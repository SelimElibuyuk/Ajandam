import 'package:ajandam/data/db/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

ItemsCompanion _task(String id, {String title = 'Dişçi'}) =>
    ItemsCompanion.insert(
      id: id,
      kind: 'task',
      title: title,
      date: const Value('2026-11-20'),
      lifecycleAnchorDate: const Value('2026-11-20'),
      createdAt: 1,
      updatedAt: 1,
    );

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('görev kaydedilir ve varsayılan değerleri atanır', () async {
    await db.into(db.items).insert(_task('1'));

    final item = await db.select(db.items).getSingle();

    expect(item.title, 'Dişçi');
    expect(item.priority, 0);
    expect(item.rolledCount, 0);
    expect(item.allDay, isFalse);
    expect(item.lifecycleAnchorDate, '2026-11-20');
    expect(item.doneAt, isNull);
  });

  test('başlık 200 karakteri geçemez', () async {
    expect(
      () => db.into(db.items).insert(_task('1', title: 'a' * 201)),
      throwsA(isA<InvalidDataException>()),
    );
  });

  test('yabancı anahtarlar zorunludur', () async {
    expect(
      () => db
          .into(db.reminders)
          .insert(
            RemindersCompanion.insert(
              id: 'r1',
              itemId: 'olmayan',
              offsetMin: 15,
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('senkron kuyruğu kayıt sırasını korur', () async {
    for (final op in ['create', 'update', 'delete']) {
      await db
          .into(db.syncQueue)
          .insert(
            SyncQueueCompanion.insert(itemId: '1', op: op, payloadJson: '{}'),
          );
    }

    final rows = await (db.select(
      db.syncQueue,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

    expect(rows.map((r) => r.op), ['create', 'update', 'delete']);
  });

  test('sürüm 1 veritabanı yükseltilir, girdiler kalır', () async {
    final fresh = AppDatabase(NativeDatabase.memory());
    final ddl = [
      for (final row
          in await fresh
              .customSelect(
                "SELECT sql FROM sqlite_master WHERE sql IS NOT NULL "
                "AND name NOT IN ('items_series_id', 'sqlite_sequence', "
                "'habits', 'habit_logs', 'habit_freezes')",
              )
              .get())
        row
            .read<String>('sql')
            .replaceAll(
              RegExp(r',\s*"(end_date|series_id|original_date)" TEXT NULL'),
              '',
            ),
    ];
    await fresh.close();
    expect(ddl.any((sql) => sql.contains('series_id')), isFalse);

    final old = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final sql in ddl) {
            raw.execute(sql);
          }
          raw.execute(
            "INSERT INTO items (id, kind, title, date, created_at, updated_at) "
            "VALUES ('eski', 'task', 'Market', '2026-11-20', 1, 1)",
          );
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    await old
        .into(old.items)
        .insert(
          _task('yeni').copyWith(
            seriesId: const Value('seri'),
            originalDate: const Value('2026-11-21'),
          ),
        );

    final rows = await old.select(old.items).get();
    expect(rows.map((r) => r.title), ['Market', 'Dişçi']);
    expect(rows.last.seriesId, 'seri');
    await old.close();
  });

  test('sürüm 2 veritabanına alışkanlık tabloları eklenir', () async {
    final fresh = AppDatabase(NativeDatabase.memory());
    final ddl = [
      for (final row
          in await fresh
              .customSelect(
                "SELECT sql FROM sqlite_master WHERE sql IS NOT NULL "
                "AND name NOT IN ('sqlite_sequence', 'habits', 'habit_logs', "
                "'habit_freezes')",
              )
              .get())
        row.read<String>('sql'),
    ];
    await fresh.close();

    final old = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final sql in ddl) {
            raw.execute(sql);
          }
          raw.execute(
            "INSERT INTO items (id, kind, title, date, created_at, updated_at) "
            "VALUES ('eski', 'task', 'Market', '2026-11-20', 1, 1)",
          );
          raw.execute('PRAGMA user_version = 2');
        },
      ),
    );
    await old
        .into(old.habits)
        .insert(
          HabitsCompanion.insert(
            id: 'h',
            title: 'Su',
            startDate: '2026-11-20',
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    await old
        .into(old.habitLogs)
        .insert(
          HabitLogsCompanion.insert(
            habitId: 'h',
            date: '2026-11-20',
            count: 1,
            updatedAt: 1,
          ),
        );

    expect((await old.select(old.items).get()).single.title, 'Market');
    expect((await old.select(old.habitLogs).get()).single.count, 1);
    await old.close();
  });

  test('sürüm 3 veritabanına dondurma tablosu eklenir, geçmiş kalır', () async {
    final fresh = AppDatabase(NativeDatabase.memory());
    final ddl = [
      for (final row
          in await fresh
              .customSelect(
                "SELECT sql FROM sqlite_master WHERE sql IS NOT NULL "
                "AND name NOT IN ('sqlite_sequence', 'habit_freezes')",
              )
              .get())
        row.read<String>('sql'),
    ];
    await fresh.close();
    expect(ddl.any((sql) => sql.contains('habit_freezes')), isFalse);

    final old = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final sql in ddl) {
            raw.execute(sql);
          }
          raw.execute(
            "INSERT INTO habits (id, title, start_date, sort_order, color, "
            "created_at, updated_at) "
            "VALUES ('h', 'Su', '2026-11-01', 0, 0, 1, 1)",
          );
          raw.execute(
            "INSERT INTO habit_logs (habit_id, date, count, updated_at) "
            "VALUES ('h', '2026-11-18', 1, 1)",
          );
          raw.execute('PRAGMA user_version = 3');
        },
      ),
    );
    await old
        .into(old.habitFreezes)
        .insert(
          HabitFreezesCompanion.insert(
            habitId: 'h',
            date: '2026-11-19',
            frozen: true,
          ),
        );

    expect((await old.select(old.habits).get()).single.title, 'Su');
    expect((await old.select(old.habitLogs).get()).single.date, '2026-11-18');
    expect((await old.select(old.habitFreezes).get()).single.frozen, isTrue);
    await old.close();
  });
}
