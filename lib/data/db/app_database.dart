import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Calendars,
    Items,
    Reminders,
    SyncQueue,
    Settings,
    Habits,
    HabitLogs,
    HabitFreezes,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'ajandam',
              native: const DriftNativeOptions(shareAcrossIsolates: true),
            ),
      );

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(items, items.endDate);
        await m.addColumn(items, items.seriesId);
        await m.addColumn(items, items.originalDate);
        await m.createIndex(itemsSeriesId);
      }
      if (from < 3) {
        await m.createTable(habits);
        await m.createTable(habitLogs);
      }
      if (from < 4) {
        await m.createTable(habitFreezes);
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
