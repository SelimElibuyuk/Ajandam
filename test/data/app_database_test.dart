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
}
