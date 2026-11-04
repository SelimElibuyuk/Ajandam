import 'dart:async';
import 'dart:convert';

import 'dates.dart';
import 'item.dart';
import 'recurrence.dart';
import 'reminder_planner.dart';
import 'rollover.dart';
import 'settings.dart';
import 'widget_snapshot.dart';

abstract class ItemStore {
  Future<AgendaItem?> byId(String id);
  Future<void> insert(AgendaItem item);
  Future<void> update(AgendaItem item);

  /// Hepsini tek işlemde yazar, listeler bir kez yenilenir.
  Future<void> updateAll(List<AgendaItem> items);

  /// Bu günlerin girdileri ve daha önceden kalan tamamlanmamış görevler.
  Future<List<AgendaItem>> itemsAround(DateTime first, DateTime last);

  /// Silinmemiş ve tamamlanmamış tüm girdiler.
  Future<List<AgendaItem>> openItems();
  Future<void> purgeDeletedBefore(DateTime time);
  Future<void> purge(String id);

  /// Serinin [from] ve sonrasındaki tekrar kayıtlarını siler.
  Future<void> removeOccurrences(String seriesId, DateTime from);
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

/// Tekrarların hatırlatmaları bu kadar gün ilerisi için kurulur; saatlik arka
/// plan işi pencereyi kaydırır.
const occurrenceDays = 14;
const snoozeMinutes = 10;

const _replanDelay = Duration(milliseconds: 400);
const _rearmDelay = Duration(seconds: 2);
const _widgetDelay = Duration(milliseconds: 100);

class ItemService {
  ItemService({
    required this._store,
    required this._settings,
    required this._reminders,
    required this._newId,
    this._deferReplan = false,
    this._widget = const NoWidget(),
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
  final WidgetGateway _widget;
  Timer? _replanTimer;
  Timer? _widgetTimer;
  bool _rearmPending = false;

  /// [kind] verilmezse süre veya bitiş günü olan girdi etkinlik olur.
  /// Saatli etkinliğin süresi yoksa bir saat sayılır.
  Future<AgendaItem> create({
    required String title,
    required DateTime day,
    DateTime? start,
    int? durationMin,
    int? reminderMin,
    String? notes,
    bool important = false,
    ItemKind? kind,
    DateTime? endDay,
    Recurrence? recurrence,
  }) async {
    final now = _clock();
    final isEvent =
        (kind ?? _autoKind(start, durationMin, endDay)) == ItemKind.event;
    final first =
        recurrence?.align(dayOnly(start ?? day)) ?? dayOnly(start ?? day);
    final at = start == null
        ? null
        : DateTime(
            first.year,
            first.month,
            first.day,
            start.hour,
            start.minute,
          );
    final minutes = (durationMin ?? 0) > 0 ? durationMin! : 60;
    final lastDay =
        isEvent && at == null && endDay != null && endDay.isAfter(first)
        ? dayOnly(endDay)
        : null;
    final item = AgendaItem(
      id: _newId(),
      kind: isEvent ? ItemKind.event : ItemKind.task,
      title: title,
      notes: notes,
      day: first,
      start: at,
      end: isEvent && at != null ? at.add(Duration(minutes: minutes)) : null,
      endDay: lastDay,
      important: important,
      anchorDay: isEvent || recurrence != null ? null : first,
      reminderMin: at == null ? null : reminderMin,
      recurrence: recurrence,
      createdAt: now,
      updatedAt: now,
    );
    await _store.insert(item);
    await _replan();
    return item;
  }

  static ItemKind _autoKind(
    DateTime? start,
    int? durationMin,
    DateTime? endDay,
  ) => (start != null && (durationMin ?? 0) > 0) || endDay != null
      ? ItemKind.event
      : ItemKind.task;

  /// Düzenleme ekranından gelen değişikliği görev ömrü kurallarıyla kaydeder.
  /// Tekrar verilirse yalnızca o günün kaydı değişir.
  Future<void> save(AgendaItem edited) async {
    final old = await _store.byId(edited.id);
    if (old == null) return;
    final today = dayOnly(_clock());
    var anchor = edited.anchorDay;
    if (!edited.isTask || edited.recurrence != null || edited.isOccurrence) {
      anchor = null;
    } else if (anchor == null || edited.day != old.day) {
      anchor = edited.day;
    } else if (old.important && !edited.important) {
      anchor = today;
    }
    final day = edited.isSeries
        ? edited.recurrence!.align(edited.day)
        : edited.day;
    await _store.update(
      _shiftTo(edited, day).copyWith(
        anchorDay: anchor,
        snoozedUntil: edited.start == old.start ? edited.snoozedUntil : null,
        rolledCount: edited.isSeries ? 0 : null,
        doneAt: edited.isSeries ? null : edited.doneAt,
        updatedAt: _clock(),
      ),
    );
    await _replan();
  }

  static AgendaItem _shiftTo(AgendaItem item, DateTime day) {
    final shift = daysBetween(item.day, day);
    if (shift == 0) return item;
    return item.copyWith(
      day: day,
      start: item.start == null ? null : addDays(item.start!, shift),
      end: item.end == null ? null : addDays(item.end!, shift),
      endDay: item.endDay == null ? null : addDays(item.endDay!, shift),
    );
  }

  /// Tekrarı ve sonrakileri değiştirir: Seri o günden ikiye bölünür, geçmiş
  /// tekrarlar olduğu gibi kalır.
  Future<void> saveFollowing(AgendaItem edited) async {
    final seriesId = edited.seriesId;
    final from = edited.originalDay;
    if (seriesId == null || from == null) return save(edited);
    final series = await _store.byId(seriesId);
    if (series == null) return;
    final now = _clock();
    await _store.removeOccurrences(seriesId, from);
    final rule = edited.recurrence;
    var next = edited.copyWith(
      id: from == series.day ? series.id : _newId(),
      seriesId: null,
      originalDay: null,
      doneAt: null,
      rolledCount: 0,
      snoozedUntil: null,
      anchorDay: rule == null && edited.isTask ? edited.day : null,
      createdAt: from == series.day ? series.createdAt : now,
      updatedAt: now,
    );
    if (rule != null) next = _shiftTo(next, rule.align(next.day));
    if (from == series.day) {
      await _store.update(next);
    } else {
      await _store.update(
        series.copyWith(
          recurrence: series.recurrence!.endingBefore(from),
          updatedAt: now,
        ),
      );
      await _store.insert(next);
    }
    await _replan();
  }

  /// Tekrarı ve sonrakileri siler, geçmiş tekrarlar kalır.
  Future<void> deleteFollowing(AgendaItem occurrence) async {
    final seriesId = occurrence.seriesId;
    final from = occurrence.originalDay;
    if (seriesId == null || from == null) return delete(occurrence.id);
    final series = await _store.byId(seriesId);
    if (series == null) return;
    if (from == series.day) return delete(series.id);
    final now = _clock();
    await _store.removeOccurrences(seriesId, from);
    await _store.update(
      series.copyWith(
        recurrence: series.recurrence!.endingBefore(from),
        updatedAt: now,
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
    final restored = item.isTask && item.recurrence == null
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
    await applyWidgetActions();
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
    final widgetTimer = _widgetTimer;
    if (widgetTimer != null) {
      widgetTimer.cancel();
      await _publishWidget();
    }
    final timer = _replanTimer;
    if (timer == null) return;
    timer.cancel();
    _replanTimer = null;
    final rearm = _rearmPending;
    _rearmPending = false;
    await _applyPlan(rearm: rearm);
  }

  void dispose() {
    _replanTimer?.cancel();
    _widgetTimer?.cancel();
  }

  /// Widget'ta dokunulan kutuları kalıcı kayda işler.
  Future<void> applyWidgetActions() async {
    final actions = await _widget.takeActions();
    if (actions.isEmpty) return;
    final changed = <AgendaItem>[];
    for (final action in actions) {
      final item = await _store.byId(action.id);
      if (item == null) continue;
      changed.add(
        item.copyWith(
          doneAt: action.done ? action.at : null,
          updatedAt: action.at,
        ),
      );
    }
    if (changed.isNotEmpty) await _store.updateAll(changed);
    await _replan();
  }

  Future<void> _publishWidget() async {
    _widgetTimer = null;
    final now = _clock();
    final today = dayOnly(now);
    final settings = await _settings.load();
    final items = await _store.itemsAround(
      addDays(today, -1),
      addDays(today, 7),
    );
    await _widget.publish(
      jsonEncode(
        buildSnapshot(items, today: today, now: now, settings: settings),
      ),
      widgetRefreshTimes(items, now),
    );
  }

  Future<void> _replan({bool rearm = false}) async {
    if (!_deferReplan) {
      await _applyPlan(rearm: rearm);
      await _publishWidget();
      return;
    }
    _widgetTimer?.cancel();
    _widgetTimer = Timer(_widgetDelay, _publishWidget);
    _rearmPending = _rearmPending || rearm;
    _replanTimer?.cancel();
    _replanTimer = Timer(
      _rearmPending ? _rearmDelay : _replanDelay,
      flushReplan,
    );
  }

  Future<void> _applyPlan({required bool rearm}) async {
    final settings = await _settings.load();
    final now = _clock();
    final items = {for (final item in await _store.openItems()) item.id: item};
    final today = dayOnly(now);
    final ahead = await _store.itemsAround(
      today,
      addDays(today, occurrenceDays),
    );
    for (final item in ahead.where((i) => i.isOccurrence && !i.isDone)) {
      items.putIfAbsent(item.id, () => item);
    }
    await _reminders.replaceAll(
      planNotifications(items.values, settings.lifecycle, now),
      rearm: rearm,
    );
  }
}
