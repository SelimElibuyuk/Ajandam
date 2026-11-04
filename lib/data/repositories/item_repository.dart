import 'package:drift/drift.dart';

import '../../domain/dates.dart';
import '../../domain/item.dart' as domain;
import '../../domain/item.dart' show AgendaItem;
import '../../domain/item_service.dart';
import '../../domain/recurrence.dart';
import '../db/app_database.dart';

class ItemRepository implements ItemStore {
  ItemRepository(this._db);

  final AppDatabase _db;

  $ItemsTable get _items => _db.items;
  $RemindersTable get _reminders => _db.reminders;

  JoinedSelectStatement<HasResultSet, dynamic> _select(
    Expression<bool> filter,
  ) => _db.select(_items).join([
    leftOuterJoin(_reminders, _reminders.itemId.equalsExp(_items.id)),
  ])..where(filter);

  List<AgendaItem> _map(List<TypedResult> rows) => [
    for (final row in rows)
      _toDomain(row.readTable(_items), row.readTableOrNull(_reminders)),
  ];

  Expression<bool> _inDays(DateTime first, DateTime last) {
    final from = dayOnly(first).millisecondsSinceEpoch;
    final to = addDays(dayOnly(last), 1).millisecondsSinceEpoch - 1;
    return _items.date.isBetweenValues(dayKey(first), dayKey(last)) |
        _items.startAt.isBetweenValues(from, to) |
        (_items.endDate.isBiggerOrEqualValue(dayKey(first)) &
            _items.date.isSmallerOrEqualValue(dayKey(last)));
  }

  Expression<bool> get _alive => _items.deletedAt.isNull();
  Expression<bool> get _single => _items.rrule.isNull();

  /// [first]-[last] günlerinin girdileri, serilerin tekrarları dahil.
  /// [overdueBefore] verilirse bu günden önce kalmış tamamlanmamış görevler de
  /// gelir; tekrarlar kendi gününde kaldığı için gelmez.
  Stream<List<AgendaItem>> watchDays(
    DateTime first,
    DateTime last, {
    DateTime? overdueBefore,
  }) {
    var filter = _alive & _single & _inDays(first, last);
    if (overdueBefore != null) {
      final day = dayOnly(overdueBefore);
      filter =
          filter |
          (_alive &
              _single &
              _items.seriesId.isNull() &
              _items.kind.equals('task') &
              _items.doneAt.isNull() &
              (_items.date.isSmallerThanValue(dayKey(day)) |
                  _items.startAt.isSmallerThanValue(
                    day.millisecondsSinceEpoch,
                  )));
    }
    // Seriler ve bu günlerdeki tekrar kayıtları da okunur ki açılım yapılsın.
    filter =
        filter |
        (_alive & _items.rrule.isNotNull()) |
        _items.originalDate.isBetweenValues(dayKey(first), dayKey(last));
    return _select(filter)
        .watch()
        .map((rows) => _compose(_map(rows), first, last, overdueBefore));
  }

  /// Satırları ekrana hazırlar: seriler günlere açılır, kaydı olan tekrar
  /// kendi kaydıyla gelir, birkaç günlük etkinlik her gününde görünür.
  List<AgendaItem> _compose(
    List<AgendaItem> rows,
    DateTime first,
    DateTime last,
    DateTime? overdueBefore,
  ) {
    final from = dayOnly(first);
    final to = dayOnly(last);
    final out = <AgendaItem>[];
    final series = {
      for (final item in rows)
        if (item.isSeries && !item.isDeleted) item.id: item,
    };
    final recorded = <String>{};
    for (var item in rows) {
      if (item.isSeries) continue;
      if (item.isOccurrence) {
        recorded.add(item.id);
        item = item.copyWith(recurrence: series[item.seriesId]?.recurrence);
      }
      if (item.isDeleted) continue;
      if (!item.lastDay.isBefore(from) && !item.day.isAfter(to)) {
        if (item.endDay == null) {
          out.add(item);
        } else {
          for (
            var d = item.day.isBefore(from) ? from : item.day;
            !d.isAfter(to) && !d.isAfter(item.lastDay);
            d = addDays(d, 1)
          ) {
            out.add(item.copyWith(day: d));
          }
        }
      } else if (overdueBefore != null &&
          item.isTask &&
          !item.isDone &&
          !item.isOccurrence &&
          item.day.isBefore(dayOnly(overdueBefore))) {
        out.add(item);
      }
    }
    for (final s in series.values) {
      for (final day in s.recurrence!.daysIn(s.day, from, to)) {
        if (!recorded.contains(occurrenceId(s.id, day))) {
          out.add(s.occurrenceOn(day));
        }
      }
    }
    return out;
  }

  Stream<AgendaItem?> watchItem(String id) {
    final series = _seriesOf(id);
    if (series == null) {
      return _select(_items.id.equals(id))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _map([row]).single);
    }
    return _select(_items.id.isIn([id, series.$1]))
        .watch()
        .map((rows) => _occurrence(_map(rows), id, series));
  }

  /// Tekrar kimliğinden seri kimliği ve günü, değilse null.
  static (String, DateTime)? _seriesOf(String id) {
    final at = id.lastIndexOf('~');
    if (at < 0) return null;
    return (id.substring(0, at), parseDayKey(id.substring(at + 1)));
  }

  static AgendaItem? _occurrence(
    List<AgendaItem> rows,
    String id,
    (String, DateTime) series,
  ) {
    final parent = rows
        .where((i) => i.id == series.$1 && i.isSeries)
        .firstOrNull;
    for (final item in rows) {
      if (item.id == id) return item.copyWith(recurrence: parent?.recurrence);
    }
    return parent?.occurrenceOn(series.$2);
  }

  /// Silinen tekrarlar çöpte görünmez, geri almak için seri kullanılır.
  Stream<List<AgendaItem>> watchTrash() {
    final query = _select(
      _items.deletedAt.isNotNull() & _items.seriesId.isNull(),
    )..orderBy([OrderingTerm.desc(_items.deletedAt)]);
    return query.watch().map(_map);
  }

  /// Tekrar kimliği verilirse kaydı yoksa seriden üretilir.
  @override
  Future<AgendaItem?> byId(String id) async {
    final series = _seriesOf(id);
    if (series == null) {
      final row = await _select(_items.id.equals(id)).getSingleOrNull();
      return row == null ? null : _map([row]).single;
    }
    final rows = await _select(_items.id.isIn([id, series.$1])).get();
    return _occurrence(_map(rows), id, series);
  }

  @override
  Future<List<AgendaItem>> itemsAround(DateTime first, DateTime last) =>
      watchDays(first, last, overdueBefore: first).first;

  @override
  Future<List<AgendaItem>> openItems() async =>
      _map(await _select(_alive & _single & _items.doneAt.isNull()).get());

  @override
  Future<void> insert(AgendaItem item) => _db.transaction(() async {
    await _db.into(_items).insert(_toRow(item));
    await _writeReminder(item);
  });

  /// Kaydı olmayan tekrar ilk değişikliğinde kayıt olur.
  @override
  Future<void> update(AgendaItem item) => _db.transaction(() async {
    await _db.into(_items).insertOnConflictUpdate(_toRow(item));
    await _writeReminder(item);
  });

  @override
  Future<void> updateAll(List<AgendaItem> items) => _db.transaction(() async {
    for (final item in items) {
      await _db.into(_items).insertOnConflictUpdate(_toRow(item));
      await _writeReminder(item);
    }
  });

  @override
  Future<void> removeOccurrences(String seriesId, DateTime from) =>
      _db.transaction(() async {
        final rows =
            await (_db.select(_items)..where(
                  (t) =>
                      t.seriesId.equals(seriesId) &
                      t.originalDate.isBiggerOrEqualValue(dayKey(from)),
                ))
                .get();
        for (final row in rows) {
          await _purgeRow(row.id);
        }
      });

  /// Seri silinirse tekrar kayıtları da gider.
  @override
  Future<void> purge(String id) => _db.transaction(() async {
    final occurrences = await (_db.select(
      _items,
    )..where((t) => t.seriesId.equals(id))).get();
    for (final row in occurrences) {
      await _purgeRow(row.id);
    }
    await _purgeRow(id);
  });

  Future<void> _purgeRow(String id) async {
    await (_db.delete(_reminders)..where((r) => r.itemId.equals(id))).go();
    await (_db.delete(_items)..where((t) => t.id.equals(id))).go();
  }

  /// Silinen tekrar kaydı serinin o gününü kapatır, seriyle birlikte gider.
  @override
  Future<void> purgeDeletedBefore(DateTime time) async {
    final old =
        await (_db.select(_items)..where(
              (t) =>
                  t.deletedAt.isSmallerThanValue(_ms(time)) &
                  t.seriesId.isNull(),
            ))
            .get();
    for (final row in old) {
      await purge(row.id);
    }
  }

  Future<void> _writeReminder(AgendaItem item) async {
    await (_db.delete(_reminders)..where((r) => r.itemId.equals(item.id))).go();
    final offset = item.reminderMin;
    if (offset != null) {
      await _db
          .into(_reminders)
          .insert(
            RemindersCompanion.insert(
              id: item.id,
              itemId: item.id,
              offsetMin: offset,
            ),
          );
    }
  }

  ItemsCompanion _toRow(AgendaItem item) => ItemsCompanion.insert(
    id: item.id,
    kind: item.isTask ? 'task' : 'event',
    title: item.title,
    notes: Value(item.notes),
    startAt: Value(item.start?.millisecondsSinceEpoch),
    endAt: Value(item.end?.millisecondsSinceEpoch),
    date: Value(item.start == null ? dayKey(item.day) : null),
    endDate: Value(item.endDay == null ? null : dayKey(item.endDay!)),
    allDay: Value(!item.isTask && item.start == null),
    rrule: Value(item.isSeries ? item.recurrence!.toRrule() : null),
    seriesId: Value(item.seriesId),
    originalDate: Value(
      item.originalDay == null ? null : dayKey(item.originalDay!),
    ),
    doneAt: Value(item.doneAt?.millisecondsSinceEpoch),
    priority: Value(item.important ? 1 : 0),
    rolledCount: Value(item.rolledCount),
    lifecycleAnchorDate: Value(
      item.anchorDay == null ? null : dayKey(item.anchorDay!),
    ),
    snoozedUntil: Value(item.snoozedUntil?.millisecondsSinceEpoch),
    createdAt: item.createdAt.millisecondsSinceEpoch,
    updatedAt: item.updatedAt.millisecondsSinceEpoch,
    deletedAt: Value(item.deletedAt?.millisecondsSinceEpoch),
  );

  AgendaItem _toDomain(Item row, Reminder? reminder) {
    final start = _time(row.startAt);
    return AgendaItem(
      id: row.id,
      kind: row.kind == 'task' ? domain.ItemKind.task : domain.ItemKind.event,
      title: row.title,
      notes: row.notes,
      day: start != null ? dayOnly(start) : parseDayKey(row.date!),
      start: start,
      end: _time(row.endAt),
      doneAt: _time(row.doneAt),
      important: row.priority == 1,
      rolledCount: row.rolledCount,
      anchorDay: row.lifecycleAnchorDate == null
          ? null
          : parseDayKey(row.lifecycleAnchorDate!),
      reminderMin: reminder?.offsetMin,
      snoozedUntil: _time(row.snoozedUntil),
      deletedAt: _time(row.deletedAt),
      createdAt: _time(row.createdAt)!,
      updatedAt: _time(row.updatedAt)!,
      endDay: row.endDate == null ? null : parseDayKey(row.endDate!),
      recurrence: Recurrence.parse(row.rrule),
      seriesId: row.seriesId,
      originalDay: row.originalDate == null
          ? null
          : parseDayKey(row.originalDate!),
    );
  }

  static DateTime? _time(int? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);

  static int _ms(DateTime time) => time.millisecondsSinceEpoch;
}
