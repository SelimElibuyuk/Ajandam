import 'package:drift/drift.dart';

import '../../domain/dates.dart';
import '../../domain/habit.dart';
import '../../domain/habit_service.dart';
import '../db/app_database.dart';

class HabitRepository implements HabitStore {
  HabitRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$HabitsTable, HabitRow> _ordered() =>
      _db.select(_db.habits)..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.createdAt),
      ]);

  Stream<List<Habit>> watchHabits() =>
      _ordered().watch().map((rows) => rows.map(_toDomain).toList());

  /// Alışkanlığın tüm geçmişi; işaretleme anında yansır.
  Stream<Map<DateTime, int>> watchHistory(String habitId) => (_db.select(
    _db.habitLogs,
  )..where((t) => t.habitId.equals(habitId))).watch().map(_countsOf);

  @override
  Future<List<Habit>> habits() async =>
      (await _ordered().get()).map(_toDomain).toList();

  @override
  Future<Habit?> habitById(String id) async {
    final row = await (_db.select(
      _db.habits,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> insertHabit(Habit habit) =>
      _db.into(_db.habits).insert(_toRow(habit));

  @override
  Future<void> updateHabit(Habit habit) =>
      _db.into(_db.habits).insertOnConflictUpdate(_toRow(habit));

  @override
  Future<void> deleteHabit(String id) => _db.transaction(() async {
    await (_db.delete(_db.habitLogs)..where((t) => t.habitId.equals(id))).go();
    await (_db.delete(_db.habits)..where((t) => t.id.equals(id))).go();
  });

  @override
  Future<Map<String, Map<DateTime, int>>> counts(
    DateTime from,
    DateTime to,
  ) async {
    final rows = await (_db.select(
      _db.habitLogs,
    )..where((t) => t.date.isBetweenValues(dayKey(from), dayKey(to)))).get();
    final result = <String, Map<DateTime, int>>{};
    for (final row in rows) {
      (result[row.habitId] ??= {})[parseDayKey(row.date)] = row.count;
    }
    return result;
  }

  @override
  Future<Map<DateTime, int>> history(String habitId) async => _countsOf(
    await (_db.select(
      _db.habitLogs,
    )..where((t) => t.habitId.equals(habitId))).get(),
  );

  @override
  Future<void> setCount(
    String habitId,
    DateTime day,
    int count,
    DateTime at,
  ) async {
    if (count <= 0) {
      await (_db.delete(_db.habitLogs)..where(
            (t) => t.habitId.equals(habitId) & t.date.equals(dayKey(day)),
          ))
          .go();
      return;
    }
    await _db
        .into(_db.habitLogs)
        .insertOnConflictUpdate(
          HabitLogsCompanion.insert(
            habitId: habitId,
            date: dayKey(day),
            count: count,
            updatedAt: at.millisecondsSinceEpoch,
          ),
        );
  }

  Map<DateTime, int> _countsOf(List<HabitLogRow> rows) => {
    for (final row in rows) parseDayKey(row.date): row.count,
  };

  HabitsCompanion _toRow(Habit h) => HabitsCompanion.insert(
    id: h.id,
    title: h.title,
    weekdays: Value(
      h.weekdays.isEmpty ? null : (h.weekdays.toList()..sort()).join(','),
    ),
    target: Value(h.target),
    color: Value(h.color),
    startDate: dayKey(h.startDay),
    sortOrder: Value(h.order),
    createdAt: h.createdAt.millisecondsSinceEpoch,
    updatedAt: h.updatedAt.millisecondsSinceEpoch,
  );

  Habit _toDomain(HabitRow r) => Habit(
    id: r.id,
    title: r.title,
    weekdays: r.weekdays == null || r.weekdays!.isEmpty
        ? const {}
        : r.weekdays!.split(',').map(int.parse).toSet(),
    target: r.target,
    color: r.color,
    startDay: parseDayKey(r.startDate),
    order: r.sortOrder,
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
  );
}
