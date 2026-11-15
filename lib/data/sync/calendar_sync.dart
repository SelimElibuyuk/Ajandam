import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/dates.dart';
import '../../domain/recurrence.dart';
import '../db/app_database.dart';
import 'calendar_mapping.dart';
import 'device_calendar.dart';

/// Takvimden bugünün bu kadar gün öncesi ve sonrası okunur.
const pastDays = 30;
const futureDays = 366;

/// Bir eşitlemede bundan fazla girdi birden “takvimden silinmiş” görünürse
/// silme yapılmaz: takvim verisi geçici olarak boş okunmuş olabilir.
const _massDeleteLimit = 10;

class SyncResult {
  const SyncResult({
    this.pushed = 0,
    this.pulled = 0,
    this.removed = 0,
    this.permission = true,
  });

  final int pushed;
  final int pulled;
  final int removed;
  final bool permission;

  @override
  String toString() => 'gönderilen $pushed, alınan $pulled, kalkan $removed';
}

/// Uygulama ile telefonun takvimi (Google hesabı) arasındaki iki yönlü eşleme.
///
/// Her girdi takvimdeki satırıyla [Item.googleEventId] üzerinden bağlıdır.
/// Takvim tarafındaki değişiklik satırın özetinden ([Item.googleEtag]),
/// uygulamadaki değişiklik [Item.updatedAt] ile son eşitlemenin
/// ([Item.remoteUpdatedAt]) karşılaştırmasından anlaşılır. İki taraf da
/// değiştiyse takvim kazanır; silme her zaman kazanır.
class CalendarSync {
  CalendarSync({
    required this._db,
    required this._gateway,
    required this._newId,
    DateTime Function()? clock,
    this.onLocalChange,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final CalendarGateway _gateway;
  final String Function() _newId;
  final DateTime Function() _clock;

  /// Uygulamadaki girdiler değişince (bildirimler ve widget yenilensin diye).
  Future<void> Function()? onLocalChange;

  Future<SyncResult?>? _running;
  bool _again = false;
  Timer? _debounce;

  $ItemsTable get _items => _db.items;

  // region Bağlantı

  /// Eşitlenen takvimler; boşsa bağlı değil.
  Future<List<Calendar>> shownCalendars() =>
      (_db.select(_db.calendars)..where((c) => c.isVisible.equals(true))).get();

  Stream<List<Calendar>> watchCalendars() => _db.select(_db.calendars).watch();

  Future<bool> isConnected() async => (await shownCalendars()).isNotEmpty;

  /// Gösterilecek takvimleri ve yeni girdilerin yazılacağı takvimi kaydeder.
  /// Listeden çıkan takvimin girdileri uygulamadan kalkar.
  Future<void> configure({
    required List<DeviceCalendarInfo> shown,
    required DeviceCalendarInfo target,
  }) async {
    final all = {for (final c in shown) c.id: c, target.id: target};
    await _db.transaction(() async {
      for (final c in all.values) {
        final account = '${c.accountType}:${c.account}';
        await _db
            .into(_db.accounts)
            .insertOnConflictUpdate(
              AccountsCompanion.insert(
                id: account,
                provider: c.isGoogle ? 'google' : c.accountType,
                email: c.account,
                connectedAt: _clock().millisecondsSinceEpoch,
              ),
            );
        await _db
            .into(_db.calendars)
            .insertOnConflictUpdate(
              CalendarsCompanion.insert(
                id: '${c.id}',
                accountId: account,
                googleCalendarId: '${c.id}',
                name: c.name,
                color: Value(c.color?.toRadixString(16)),
                isVisible: const Value(true),
                isDefault: Value(c.id == target.id),
                accessRole: c.role,
              ),
            );
      }
      final hidden = await (_db.select(
        _db.calendars,
      )..where((c) => c.id.isNotIn([for (final id in all.keys) '$id']))).get();
      for (final c in hidden) {
        await (_db.update(
          _db.calendars,
        )..where((t) => t.id.equals(c.id))).write(
          const CalendarsCompanion(
            isVisible: Value(false),
            isDefault: Value(false),
          ),
        );
        await _purgeGoogleItems(calendarId: c.id);
      }
    });
    await onLocalChange?.call();
  }

  /// Google'dan gelen girdiler uygulamadan kalkar; uygulamada eklenenler
  /// kalır ve takvimdeki kopyalarına dokunulmaz.
  Future<void> disconnect() async {
    _debounce?.cancel();
    await _db.transaction(() async {
      await _purgeGoogleItems();
      await _db
          .update(_items)
          .write(
            const ItemsCompanion(
              calendarId: Value(null),
              googleEventId: Value(null),
              googleEtag: Value(null),
              remoteUpdatedAt: Value(null),
            ),
          );
      await _db.delete(_db.syncQueue).go();
      await _db.delete(_db.calendars).go();
      await _db.delete(_db.accounts).go();
    });
    await onLocalChange?.call();
  }

  Future<void> _purgeGoogleItems({String? calendarId}) async {
    final query = _db.select(_items)..where((t) => t.source.equals('google'));
    if (calendarId != null) query.where((t) => t.calendarId.equals(calendarId));
    final ids = [for (final r in await query.get()) r.id];
    await _purgeSilently(ids);
  }

  /// Takvime haber vermeden siler (takvimdeki zaten yok ya da bilerek
  /// bırakılıyor). Serinin tekrar kayıtları da gider.
  Future<void> _purgeSilently(List<String> ids) async {
    if (ids.isEmpty) return;
    final occurrences = await (_db.select(
      _items,
    )..where((t) => t.seriesId.isIn(ids))).get();
    final all = [...ids, for (final o in occurrences) o.id];
    await (_db.delete(_db.reminders)..where((r) => r.itemId.isIn(all))).go();
    await (_db.delete(_items)..where((t) => t.id.isIn(all))).go();
  }

  // endregion

  // region Zamanlama

  /// Değişiklikler bir süre birikir, sonra tek eşitleme yapılır.
  void schedule([Duration delay = const Duration(seconds: 2)]) {
    _debounce?.cancel();
    _debounce = Timer(delay, () => unawaited(sync()));
  }

  void dispose() => _debounce?.cancel();

  /// Aynı anda tek eşitleme çalışır; çalışırken istenen yenisi ardından gelir.
  Future<SyncResult?> sync() async {
    if (_running != null) {
      _again = true;
      return _running;
    }
    final run = _syncLoop();
    _running = run;
    try {
      return await run;
    } finally {
      _running = null;
    }
  }

  /// Son eşitlemenin hatası; başarılı eşitlemede temizlenir.
  Object? lastError;

  Future<SyncResult?> _syncLoop() async {
    SyncResult? result;
    do {
      _again = false;
      try {
        result = await _syncOnce();
        lastError = null;
      } catch (error) {
        // Takvim okunamazsa uygulama çalışmaya devam eder, sonra yeniden denenir.
        lastError = error;
        result = null;
      }
    } while (_again);
    return result;
  }

  // endregion

  Future<SyncResult?> _syncOnce() async {
    var calendars = await shownCalendars();
    if (calendars.isEmpty) return null;
    if (!await _gateway.hasPermission()) {
      return const SyncResult(permission: false);
    }

    // Telefonda artık olmayan takvim (hesap kaldırıldı) eşitlenmez.
    final infos = {for (final c in await _gateway.calendars()) '${c.id}': c};
    calendars = [
      for (final c in calendars)
        if (infos.containsKey(c.id)) c,
    ];
    if (calendars.isEmpty) return const SyncResult();
    final selected = {for (final c in calendars) int.parse(c.id)};
    final writable = {
      for (final c in calendars)
        if (infos[c.id]!.writable) int.parse(c.id),
    };
    final target = calendars.firstWhere(
      (c) => c.isDefault && writable.contains(int.parse(c.id)),
      orElse: () => calendars.firstWhere(
        (c) => writable.contains(int.parse(c.id)),
        orElse: () => calendars.first,
      ),
    );
    final targetId = int.parse(target.id);

    final now = _clock();
    final nowMs = now.millisecondsSinceEpoch;
    final today = dayOnly(now);
    final from = addDays(today, -pastDays);
    final to = addDays(today, futureDays);
    var pushed = 0, pulled = 0, removed = 0;
    final touched = <int>{};

    // 1. Kalıcı silinen girdilerin takvimdeki karşılıkları.
    for (final q in await (_db.select(
      _db.syncQueue,
    )..where((q) => q.op.equals('delete'))).get()) {
      final event = (jsonDecode(q.payloadJson) as Map)['event'] as int?;
      if (event != null) {
        await _gateway.delete(event);
        pushed++;
      }
      await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(q.id))).go();
    }

    // 2. Takvimden oku.
    final raw = await _gateway.events(
      selected.toList(),
      from.millisecondsSinceEpoch,
      to.millisecondsSinceEpoch,
    );
    final exceptions = <RemoteEvent>[];
    final unsupported = <int>[];
    final remote = <String, RemoteEvent>{};
    final masters = <String, RemoteEvent>{};
    for (final e in raw) {
      if (e.isException) {
        exceptions.add(e);
        continue;
      }
      if (e.canceled) continue;
      if (e.rrule != null) {
        final first = e.allDay ? utcDay(e.start) : localDay(e.start);
        if (e.rdate != null || supportedRule(e.rrule!, first) == null) {
          unsupported.add(int.parse(e.key));
          continue;
        }
        masters[e.key] = e;
      }
      remote[e.key] = e;
    }
    for (final e in await _gateway.instances(
      unsupported,
      from.millisecondsSinceEpoch,
      to.millisecondsSinceEpoch,
    )) {
      if (!e.canceled) remote[e.key] = e;
    }

    // 3. Bağlı girdileri karşılaştır.
    var rows = await _db.select(_items).get();
    final missing = <Item>[];
    var linked = 0;
    for (final row in rows) {
      final key = row.googleEventId;
      if (key == null || row.seriesId != null) continue;
      final calendar = int.tryParse(row.calendarId ?? '');
      if (calendar == null || !selected.contains(calendar)) continue;
      linked++;
      final e = remote.remove(key);
      if (e == null) {
        if (_overlaps(row, from, to)) missing.add(row);
        continue;
      }
      final localChanged = row.updatedAt > (row.remoteUpdatedAt ?? 0);
      final canWrite = !row.readOnly && writable.contains(calendar);
      if (row.deletedAt != null) {
        if (localChanged && canWrite && !key.contains('@')) {
          await _gateway.delete(int.parse(key));
          touched.add(calendar);
          pushed++;
          await _unlink(row);
        } else if (fingerprint(e) != row.googleEtag) {
          // Takvimde değişti ama uygulamada çöpte: çöpte kalır.
          await _markSynced(row, etag: fingerprint(e));
        }
        continue;
      }
      final fp = fingerprint(e);
      if (fp != row.googleEtag) {
        if (await _applyRemote(row, e, fp, nowMs)) pulled++;
      } else if (localChanged) {
        if (canWrite && !key.contains('@')) {
          final write = writeFromRow(row);
          await _gateway.update(int.parse(key), write);
          touched.add(calendar);
          pushed++;
          await _markSynced(row, etag: writtenFingerprint(write));
        } else {
          await _markSynced(row, etag: fp);
        }
      }
    }

    // 4. Takvimde artık olmayanlar.
    if (missing.length <= _massDeleteLimit || missing.length * 2 <= linked) {
      for (final row in missing) {
        final localChanged = row.updatedAt > (row.remoteUpdatedAt ?? 0);
        final calendar = int.parse(row.calendarId!);
        if (row.deletedAt != null) {
          await _unlink(row);
        } else if (row.source == 'google') {
          await _purgeSilently([row.id]);
          removed++;
        } else if (localChanged && writable.contains(calendar)) {
          // Takvimde silinmiş ama uygulamada değişmiş: yeniden yazılır.
          final write = writeFromRow(row);
          final id = await _gateway.insert(calendar, write);
          touched.add(calendar);
          pushed++;
          await _link(row, calendar, '$id', etag: writtenFingerprint(write));
        } else {
          await (_db.update(_items)..where((t) => t.id.equals(row.id))).write(
            ItemsCompanion(
              deletedAt: Value(nowMs),
              updatedAt: Value(nowMs),
              remoteUpdatedAt: Value(nowMs),
              googleEventId: const Value(null),
              googleEtag: const Value(null),
            ),
          );
          removed++;
        }
      }
    }

    // 5. Uygulamada eklenip henüz takvime yazılmamış girdiler.
    for (final row in rows) {
      if (row.googleEventId != null ||
          row.seriesId != null ||
          row.deletedAt != null ||
          row.source != null ||
          !_relevant(row, today)) {
        continue;
      }
      final match = _findTwin(row, remote.values, writable);
      if (match != null) {
        remote.remove(match.key);
        await _link(row, match.calendarId, match.key);
        continue;
      }
      if (!writable.contains(targetId)) continue;
      final write = writeFromRow(row);
      final id = await _gateway.insert(targetId, write);
      touched.add(targetId);
      pushed++;
      await _link(row, targetId, '$id', etag: writtenFingerprint(write));
    }

    // 6. Takvimde eklenip uygulamada olmayanlar.
    for (final e in remote.values) {
      await _import(e, writable, nowMs);
      pulled++;
    }

    // 7. Serilerin tek tek değişen, iptal edilen tekrarları.
    rows = await _db.select(_items).get();
    pulled += await _pullExceptions(rows, exceptions, masters, nowMs);
    rows = await _db.select(_items).get();
    final pushedExceptions = await _pushExceptions(rows, writable);
    pushed += pushedExceptions.length;
    touched.addAll(pushedExceptions);

    if (touched.isNotEmpty) await _gateway.requestSync(touched.toList());
    await (_db.update(_db.calendars)..where((c) => c.isVisible.equals(true)))
        .write(CalendarsCompanion(lastSyncedAt: Value(nowMs)));
    if (pulled > 0 || removed > 0) await onLocalChange?.call();
    return SyncResult(pushed: pushed, pulled: pulled, removed: removed);
  }

  // region Satır işlemleri

  static bool _overlaps(Item row, DateTime from, DateTime to) {
    final first = rowDay(row);
    if (row.rrule != null) {
      final until = Recurrence.parse(row.rrule)?.until;
      return !first.isAfter(to) && (until == null || !until.isBefore(from));
    }
    return !rowLastDay(row).isBefore(from) && !first.isAfter(to);
  }

  /// Geçmişte kalan girdiler takvime taşınmaz; açık görevler taşınır.
  static bool _relevant(Item row, DateTime today) {
    if (row.rrule != null) {
      final until = Recurrence.parse(row.rrule)?.until;
      return until == null || !until.isBefore(today);
    }
    if (!rowLastDay(row).isBefore(today)) return true;
    return row.kind == 'task' && row.doneAt == null;
  }

  /// Aynı ad ve zamandaki bağsız takvim satırı: yeniden bağlanınca ya da
  /// uygulama yeniden kurulunca çift kayıt olmasın.
  static RemoteEvent? _findTwin(
    Item row,
    Iterable<RemoteEvent> remote,
    Set<int> writable,
  ) {
    final mine = EventFields.fromRow(row);
    for (final e in remote) {
      if (e.key.contains('@') || !writable.contains(e.calendarId)) continue;
      final f = fieldsFromRemote(e);
      if (f.title.toLowerCase() != mine.title.toLowerCase()) continue;
      if (f.startAt == mine.startAt && f.date == mine.date) return e;
    }
    return null;
  }

  /// [etag] boşsa takvimdeki hali sonraki eşitlemede satıra işlenir.
  Future<void> _link(Item row, int calendar, String key, {String? etag}) =>
      (_db.update(_items)..where((t) => t.id.equals(row.id))).write(
        ItemsCompanion(
          calendarId: Value('$calendar'),
          googleEventId: Value(key),
          googleEtag: Value(etag),
          remoteUpdatedAt: Value(row.updatedAt),
        ),
      );

  Future<void> _unlink(Item row) =>
      (_db.update(_items)..where((t) => t.id.equals(row.id))).write(
        ItemsCompanion(
          googleEventId: const Value(null),
          googleEtag: const Value(null),
          remoteUpdatedAt: Value(row.updatedAt),
        ),
      );

  /// [etag] boşsa sonraki eşitlemede takvimdeki hali yeniden okunur.
  Future<void> _markSynced(Item row, {required String? etag}) =>
      (_db.update(_items)..where((t) => t.id.equals(row.id))).write(
        ItemsCompanion(
          googleEtag: Value(etag),
          remoteUpdatedAt: Value(row.updatedAt),
        ),
      );

  ItemsCompanion _fields(EventFields f, Item? old, int nowMs) {
    final day = f.startAt != null ? localDay(f.startAt!) : parseDayKey(f.date!);
    final task = f.isTask && f.rrule == null;
    final moved = old == null || rowDay(old) != day;
    return ItemsCompanion(
      kind: Value(f.kind),
      title: Value(f.title),
      notes: Value(f.notes),
      allDay: Value(f.allDay),
      startAt: Value(f.startAt),
      endAt: Value(f.endAt),
      date: Value(f.startAt == null ? f.date : null),
      endDate: Value(f.endDate),
      rrule: Value(f.rrule),
      doneAt: Value(f.done ? (old?.doneAt ?? nowMs) : null),
      lifecycleAnchorDate: Value(
        !task
            ? null
            : moved
            ? dayKey(day)
            : old.lifecycleAnchorDate,
      ),
      updatedAt: Value(nowMs),
      remoteUpdatedAt: Value(nowMs),
    );
  }

  /// Takvimdeki hal satıra işlenir; true dönerse uygulamada bir şey değişti.
  Future<bool> _applyRemote(
    Item row,
    RemoteEvent e,
    String fp,
    int nowMs,
  ) async {
    final f = fieldsFromRemote(e);
    if (EventFields.fromRow(row) == f) {
      await _markSynced(row, etag: fp);
      return false;
    }
    await (_db.update(_items)..where((t) => t.id.equals(row.id))).write(
      _fields(f, row, nowMs).copyWith(googleEtag: Value(fp)),
    );
    return true;
  }

  Future<void> _import(RemoteEvent e, Set<int> writable, int nowMs) async {
    final f = fieldsFromRemote(e);
    await _db
        .into(_items)
        .insert(
          _fields(f, null, nowMs).copyWith(
            id: Value(_newId()),
            calendarId: Value('${e.calendarId}'),
            googleEventId: Value(e.key),
            googleEtag: Value(fingerprint(e)),
            source: const Value('google'),
            readOnly: Value(
              e.key.contains('@') || !writable.contains(e.calendarId),
            ),
            createdAt: Value(nowMs),
          ),
        );
  }

  /// Serinin [day] günündeki tekrarının seriden gelen hali.
  static EventFields _instanceFields(Item series, DateTime day) {
    final start = series.startAt;
    final shift = daysBetween(rowDay(series), day);
    return EventFields(
      kind: series.kind,
      title: series.title,
      notes: series.notes,
      done: false,
      allDay: series.allDay,
      startAt: start == null ? null : instanceTime(series, day),
      endAt: series.endAt == null || start == null
          ? null
          : instanceTime(series, day) + (series.endAt! - start),
      date: start == null ? dayKey(day) : null,
      endDate: series.endDate == null
          ? null
          : dayKey(addDays(parseDayKey(series.endDate!), shift)),
    );
  }

  /// Takvimdeki istisnalar ve EXDATE'ler uygulamada tekrar kaydı olur.
  Future<int> _pullExceptions(
    List<Item> rows,
    List<RemoteEvent> exceptions,
    Map<String, RemoteEvent> masters,
    int nowMs,
  ) async {
    final series = {
      for (final r in rows)
        if (r.rrule != null && r.googleEventId != null && r.seriesId == null)
          r.googleEventId!: r,
    };
    final occurrences = {
      for (final r in rows)
        if (r.seriesId != null) r.id: r,
    };
    final byKey = {
      for (final r in occurrences.values)
        if (r.googleEventId != null) r.googleEventId!: r,
    };
    var changed = 0;

    Future<void> upsert(
      Item parent,
      DateTime day,
      EventFields f, {
      required bool deleted,
      String? key,
      String? etag,
    }) async {
      final id = occurrenceId(parent.id, day);
      final old = byKey[key] ?? occurrences[id];
      await _db
          .into(_items)
          .insertOnConflictUpdate(
            _fields(f, old, nowMs).copyWith(
              id: Value(old?.id ?? id),
              seriesId: Value(parent.id),
              originalDate: Value(dayKey(day)),
              rrule: const Value(null),
              priority: Value(parent.priority),
              calendarId: Value(parent.calendarId),
              googleEventId: Value(key),
              googleEtag: Value(etag),
              source: Value(parent.source),
              readOnly: Value(parent.readOnly),
              deletedAt: Value(deleted ? (old?.deletedAt ?? nowMs) : null),
              createdAt: Value(old?.createdAt ?? nowMs),
            ),
          );
      changed++;
    }

    for (final ex in exceptions) {
      final parent = series['${ex.originalId}'];
      if (parent == null || ex.originalInstanceTime == null) continue;
      final day = instanceDay(
        ex.originalInstanceTime!,
        allDay: parent.startAt == null,
      );
      final fp = fingerprint(ex);
      final old = byKey[ex.key] ?? occurrences[occurrenceId(parent.id, day)];
      if (old != null && old.googleEtag == fp) continue;
      if (ex.canceled) {
        if (old != null && old.deletedAt != null) {
          await _markSynced(old, etag: fp);
          await (_db.update(_items)..where((t) => t.id.equals(old.id))).write(
            ItemsCompanion(googleEventId: Value(ex.key)),
          );
          continue;
        }
        await upsert(
          parent,
          day,
          _instanceFields(parent, day),
          deleted: true,
          key: ex.key,
          etag: fp,
        );
        continue;
      }
      final f = fieldsFromRemote(ex);
      if (old != null &&
          old.deletedAt == null &&
          EventFields.fromRow(old) == f) {
        await _markSynced(old, etag: fp);
        await (_db.update(_items)..where((t) => t.id.equals(old.id))).write(
          ItemsCompanion(googleEventId: Value(ex.key)),
        );
        continue;
      }
      await upsert(parent, day, f, deleted: false, key: ex.key, etag: fp);
    }

    for (final MapEntry(:key, value: master) in masters.entries) {
      final parent = series[key];
      if (parent == null) continue;
      for (final day in exdateDays(master.exdate, allDay: master.allDay)) {
        final old = occurrences[occurrenceId(parent.id, day)];
        if (old != null && old.deletedAt != null) continue;
        await upsert(
          parent,
          day,
          _instanceFields(parent, day),
          deleted: true,
          etag: 'exdate',
        );
      }
    }
    return changed;
  }

  /// Uygulamada değişen tekrarlar takvimde serinin istisnası olur.
  Future<Set<int>> _pushExceptions(List<Item> rows, Set<int> writable) async {
    final byId = {for (final r in rows) r.id: r};
    final touched = <int>{};
    for (final occ in rows) {
      if (occ.seriesId == null ||
          occ.originalDate == null ||
          occ.updatedAt <= (occ.remoteUpdatedAt ?? 0)) {
        continue;
      }
      final series = byId[occ.seriesId];
      final parentKey = series?.googleEventId;
      final calendar = int.tryParse(series?.calendarId ?? '');
      if (series == null ||
          parentKey == null ||
          parentKey.contains('@') ||
          series.readOnly ||
          calendar == null ||
          !writable.contains(calendar)) {
        continue;
      }
      final day = parseDayKey(occ.originalDate!);
      final deleted = occ.deletedAt != null;
      final current = occ.googleEventId;
      final plain =
          !deleted && EventFields.fromRow(occ) == _instanceFields(series, day);
      if (current == null && plain) {
        // Yalnızca uygulamaya ait bir değişiklik (ör. erteleme).
        await _markSynced(occ, etag: occ.googleEtag);
        continue;
      }
      String? etag;
      if (current != null && !deleted) {
        final write = writeFromRow(occ);
        await _gateway.update(int.parse(current), write);
        etag = writtenFingerprint(write);
      } else {
        if (current != null) await _gateway.delete(int.parse(current));
        final id = await _gateway.insertException(
          int.parse(parentKey),
          instanceTime(series, day),
          event: deleted ? null : writeFromRow(occ),
        );
        if (!deleted) etag = writtenFingerprint(writeFromRow(occ));
        await (_db.update(_items)..where((t) => t.id.equals(occ.id))).write(
          ItemsCompanion(
            googleEventId: Value('$id'),
            calendarId: Value('$calendar'),
          ),
        );
      }
      await _markSynced(occ, etag: etag);
      touched.add(calendar);
    }
    return touched;
  }

  // endregion
}
