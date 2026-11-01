import 'package:drift/drift.dart';

import '../../domain/dates.dart';
import '../../domain/item.dart' as domain;
import '../../domain/item.dart' show AgendaItem;
import '../../domain/item_service.dart';
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
        _items.startAt.isBetweenValues(from, to);
  }

  Expression<bool> get _alive => _items.deletedAt.isNull();

  /// [first]-[last] günlerinin girdileri. [overdueBefore] verilirse bu günden
  /// önce kalmış tamamlanmamış görevler de gelir.
  Stream<List<AgendaItem>> watchDays(
    DateTime first,
    DateTime last, {
    DateTime? overdueBefore,
  }) {
    var filter = _inDays(first, last);
    if (overdueBefore != null) {
      final day = dayOnly(overdueBefore);
      filter =
          filter |
          (_items.kind.equals('task') &
              _items.doneAt.isNull() &
              (_items.date.isSmallerThanValue(dayKey(day)) |
                  _items.startAt.isSmallerThanValue(
                    day.millisecondsSinceEpoch,
                  )));
    }
    return _select(_alive & filter).watch().map(_map);
  }

  Stream<AgendaItem?> watchItem(String id) =>
      _select(_items.id.equals(id))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _map([row]).single);

  Stream<List<AgendaItem>> watchTrash() {
    final query = _select(_items.deletedAt.isNotNull())
      ..orderBy([OrderingTerm.desc(_items.deletedAt)]);
    return query.watch().map(_map);
  }

  @override
  Future<AgendaItem?> byId(String id) async {
    final row = await _select(_items.id.equals(id)).getSingleOrNull();
    return row == null ? null : _map([row]).single;
  }

  @override
  Future<List<AgendaItem>> itemsAround(DateTime first, DateTime last) =>
      watchDays(first, last, overdueBefore: first).first;

  @override
  Future<List<AgendaItem>> openItems() async =>
      _map(await _select(_alive & _items.doneAt.isNull()).get());

  @override
  Future<void> insert(AgendaItem item) => _db.transaction(() async {
    await _db.into(_items).insert(_toRow(item));
    await _writeReminder(item);
  });

  @override
  Future<void> update(AgendaItem item) => _db.transaction(() async {
    await _db.update(_items).replace(_toRow(item));
    await _writeReminder(item);
  });

  @override
  Future<void> updateAll(List<AgendaItem> items) => _db.transaction(() async {
    for (final item in items) {
      await _db.update(_items).replace(_toRow(item));
      await _writeReminder(item);
    }
  });

  @override
  Future<void> purge(String id) => _db.transaction(() async {
    await (_db.delete(_reminders)..where((r) => r.itemId.equals(id))).go();
    await (_db.delete(_items)..where((t) => t.id.equals(id))).go();
  });

  @override
  Future<void> purgeDeletedBefore(DateTime time) async {
    final old = await (_db.select(
      _items,
    )..where((t) => t.deletedAt.isSmallerThanValue(_ms(time)))).get();
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
    );
  }

  static DateTime? _time(int? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);

  static int _ms(DateTime time) => time.millisecondsSinceEpoch;
}
