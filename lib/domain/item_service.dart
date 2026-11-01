import 'dart:async';

import 'dates.dart';
import 'item.dart';
import 'reminder_planner.dart';
import 'rollover.dart';
import 'settings.dart';

abstract class ItemStore {
  Future<AgendaItem?> byId(String id);
  Future<void> insert(AgendaItem item);
  Future<void> update(AgendaItem item);

  /// Hepsini tek işlemde yazar, listeler bir kez yenilenir.
  Future<void> updateAll(List<AgendaItem> items);

  /// Silinmemiş ve tamamlanmamış tüm girdiler.
  Future<List<AgendaItem>> openItems();
  Future<void> purgeDeletedBefore(DateTime time);
  Future<void> purge(String id);
}

abstract class SettingsStore {
  Future<AppSettings> load();
}

abstract class ReminderGateway {
  /// [rearm] true ise zaten planlı görünenleri de yeniden kurar: Android,
  /// uygulama zorla durdurulunca alarmları silmiş olabilir.
  Future<void> replaceAll(
    List<PlannedNotification> plans, {
    bool rearm = false,
  });
}

const trashDays = 30;
const snoozeMinutes = 10;

const _replanDelay = Duration(milliseconds: 400);
const _rearmDelay = Duration(seconds: 2);

class ItemService {
  ItemService({
    required this._store,
    required this._settings,
    required this._reminders,
    required this._newId,
    this._deferReplan = false,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ItemStore _store;
  final SettingsStore _settings;
  final ReminderGateway _reminders;
  final String Function() _newId;
  final DateTime Function() _clock;

  /// Arayüzde bildirimler dokunuşu bekletmez, kısa süre sonra toplu planlanır.
  /// Arka plan işlerinde süreç kapanabileceği için hemen planlanır.
  final bool _deferReplan;
  Timer? _replanTimer;
  bool _rearmPending = false;

  Future<AgendaItem> create({
    required String title,
    required DateTime day,
    DateTime? start,
    int? durationMin,
    int? reminderMin,
    String? notes,
    bool important = false,
  }) async {
    final now = _clock();
    final isEvent = start != null && (durationMin ?? 0) > 0;
    final item = AgendaItem(
      id: _newId(),
      kind: isEvent ? ItemKind.event : ItemKind.task,
      title: title,
      notes: notes,
      day: dayOnly(start ?? day),
      start: start,
      end: isEvent ? start.add(Duration(minutes: durationMin!)) : null,
      important: important,
      anchorDay: isEvent ? null : dayOnly(start ?? day),
      reminderMin: start == null ? null : reminderMin,
      createdAt: now,
      updatedAt: now,
    );
    await _store.insert(item);
    await _replan();
    return item;
  }

  /// Düzenleme ekranından gelen değişikliği görev ömrü kurallarıyla kaydeder.
  Future<void> save(AgendaItem edited) async {
    final old = await _store.byId(edited.id);
    if (old == null) return;
    final today = dayOnly(_clock());
    var anchor = edited.anchorDay;
    if (!edited.isTask) {
      anchor = null;
    } else if (anchor == null || edited.day != old.day) {
      anchor = edited.day;
    } else if (old.important && !edited.important) {
      anchor = today;
    }
    await _store.update(
      edited.copyWith(
        anchorDay: anchor,
        snoozedUntil: edited.start == old.start ? edited.snoozedUntil : null,
        updatedAt: _clock(),
      ),
    );
    await _replan();
  }

  Future<void> toggleDone(String id) async {
    final item = await _store.byId(id);
    if (item == null) return;
    final now = _clock();
    await _store.update(
      item.copyWith(doneAt: item.isDone ? null : now, updatedAt: now),
    );
    await _replan();
  }

  Future<void> complete(String id) async {
    final item = await _store.byId(id);
    if (item == null || item.isDone) return;
    final now = _clock();
    await _store.update(item.copyWith(doneAt: now, updatedAt: now));
    await _replan();
  }

  Future<void> delete(String id) async {
    final item = await _store.byId(id);
    if (item == null) return;
    final now = _clock();
    await _store.update(item.copyWith(deletedAt: now, updatedAt: now));
    await _replan();
  }

  /// Az önce silineni olduğu gibi geri koyar.
  Future<void> undoDelete(AgendaItem item) async {
    await _store.update(item);
    await _replan();
  }

  /// Çöp kutusundan geri alınan görev bugüne gelir ve sayacı sıfırlanır.
  Future<void> restore(String id) async {
    final item = await _store.byId(id);
    if (item == null) return;
    final now = _clock();
    final today = dayOnly(now);
    final restored = item.isTask
        ? item.movedTo(today, rolledBy: 0).copyWith(anchorDay: today)
        : item;
    await _store.update(restored.copyWith(deletedAt: null, updatedAt: now));
    await _replan();
  }

  Future<void> deleteForever(String id) async {
    await _store.purge(id);
    await _replan();
  }

  Future<void> extend(Iterable<String> ids) async {
    final now = _clock();
    for (final id in ids) {
      final item = await _store.byId(id);
      if (item == null) continue;
      await _store.update(
        item.copyWith(anchorDay: dayOnly(now), updatedAt: now),
      );
    }
    await _replan();
  }

  Future<void> moveToTomorrow(String id) async {
    final item = await _store.byId(id);
    if (item == null) return;
    final now = _clock();
    await _store.update(
      item
          .movedTo(addDays(dayOnly(now), 1), rolledBy: 1)
          .copyWith(updatedAt: now),
    );
    await _replan();
  }

  Future<void> snooze(String id) async {
    final item = await _store.byId(id);
    if (item == null) return;
    final now = _clock();
    await _store.update(
      item.copyWith(
        snoozedUntil: now.add(const Duration(minutes: snoozeMinutes)),
        updatedAt: now,
      ),
    );
    await _replan();
  }

  /// Gece taşıma, süresi dolan görevler ve çöp kutusu temizliği.
  /// Kaç kez çalışırsa çalışsın aynı sonucu verir.
  Future<void> runMaintenance({bool rearm = false}) async {
    final now = _clock();
    final today = dayOnly(now);
    final settings = await _settings.load();
    final rule = settings.lifecycle;
    final changed = <AgendaItem>[];
    for (final item in await _store.openItems()) {
      if (rule.isExpired(item, today)) {
        changed.add(item.copyWith(deletedAt: now, updatedAt: now));
      } else if (settings.autoRollover) {
        final moved = rollover(item, today);
        if (moved != null) changed.add(moved.copyWith(updatedAt: now));
      }
    }
    if (changed.isNotEmpty) await _store.updateAll(changed);
    await _store.purgeDeletedBefore(
      now.subtract(const Duration(days: trashDays)),
    );
    await _replan(rearm: rearm);
  }

  Future<void> replan() => _replan();

  /// Bekleyen planlamayı hemen uygular, ör. uygulama arka plana geçerken.
  Future<void> flushReplan() async {
    final timer = _replanTimer;
    if (timer == null) return;
    timer.cancel();
    _replanTimer = null;
    final rearm = _rearmPending;
    _rearmPending = false;
    await _applyPlan(rearm: rearm);
  }

  void dispose() => _replanTimer?.cancel();

  Future<void> _replan({bool rearm = false}) async {
    if (!_deferReplan) return _applyPlan(rearm: rearm);
    _rearmPending = _rearmPending || rearm;
    _replanTimer?.cancel();
    _replanTimer = Timer(
      _rearmPending ? _rearmDelay : _replanDelay,
      flushReplan,
    );
  }

  Future<void> _applyPlan({required bool rearm}) async {
    final settings = await _settings.load();
    final items = await _store.openItems();
    await _reminders.replaceAll(
      planNotifications(items, settings.lifecycle, _clock()),
      rearm: rearm,
    );
  }
}
