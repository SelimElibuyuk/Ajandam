import 'package:ajandam/data/db/app_database.dart';
import 'package:ajandam/data/repositories/item_repository.dart';
import 'package:ajandam/data/repositories/settings_repository.dart';
import 'package:ajandam/domain/item.dart';
import 'package:ajandam/domain/item_service.dart';
import 'package:ajandam/domain/reminder_planner.dart';
import 'package:ajandam/domain/settings.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeReminders implements ReminderGateway {
  List<PlannedNotification> plans = [];
  bool rearmed = false;

  @override
  Future<void> replaceAll(
    List<PlannedNotification> next, {
    bool rearm = false,
  }) async {
    plans = next;
    rearmed = rearmed || rearm;
  }
}

class _Counting implements ReminderGateway {
  _Counting(this.onCall);

  final void Function() onCall;

  @override
  Future<void> replaceAll(
    List<PlannedNotification> plans, {
    bool rearm = false,
  }) async => onCall();
}

void main() {
  late AppDatabase db;
  late ItemRepository repo;
  late SettingsRepository settings;
  late FakeReminders reminders;
  late ItemService service;
  late DateTime now;
  var nextId = 0;

  List<PlannedNotification> itemPlans() => [
    for (final plan in reminders.plans)
      if (plan.type == NotificationType.item) plan,
  ];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ItemRepository(db);
    settings = SettingsRepository(db);
    reminders = FakeReminders();
    now = DateTime(2026, 11, 20, 10);
    service = ItemService(
      store: repo,
      settings: settings,
      reminders: reminders,
      newId: () => 'id${nextId++}',
      clock: () => now,
    );
  });
  tearDown(() => db.close());

  Future<AgendaItem> reload(AgendaItem item) async =>
      (await repo.byId(item.id))!;

  group('oluşturma', () {
    test('saatsiz görev', () async {
      final item = await service.create(
        title: 'Market',
        day: DateTime(2026, 11, 20),
      );

      expect(item.isTask, isTrue);
      expect(item.isTimed, isFalse);
      expect(item.anchorDay, DateTime(2026, 11, 20));
      expect((await reload(item)).day, DateTime(2026, 11, 20));
    });

    test('saat var süre yoksa saatli görev', () async {
      final item = await service.create(
        title: 'Dişçi',
        day: DateTime(2026, 11, 21),
        start: DateTime(2026, 11, 21, 14),
        reminderMin: 15,
      );

      expect(item.isTask, isTrue);
      expect(item.isTimed, isTrue);
      expect((await reload(item)).reminderMin, 15);
      expect(itemPlans().single.when, DateTime(2026, 11, 21, 13, 45));
    });

    test('saat ve süre varsa etkinlik', () async {
      final item = await service.create(
        title: 'Sunum',
        day: DateTime(2026, 11, 21),
        start: DateTime(2026, 11, 21, 14),
        durationMin: 90,
      );

      expect(item.kind, ItemKind.event);
      expect(item.end, DateTime(2026, 11, 21, 15, 30));
      expect(item.anchorDay, isNull);
    });
  });

  group('görev ömrü', () {
    late AgendaItem item;

    setUp(() async {
      item = await service.create(title: 'Rapor', day: DateTime(2026, 11, 20));
    });

    test('gece taşınır, sayaç aynı kalır', () async {
      now = DateTime(2026, 11, 21, 0, 5);
      await service.runMaintenance();

      final moved = await reload(item);
      expect(moved.day, DateTime(2026, 11, 21));
      expect(moved.rolledCount, 1);
      expect(moved.anchorDay, DateTime(2026, 11, 20));
    });

    test('bakım tekrar çalışınca ikinci kez saymaz', () async {
      now = DateTime(2026, 11, 21, 0, 5);
      await service.runMaintenance();
      await service.runMaintenance();

      expect((await reload(item)).rolledCount, 1);
    });

    test('süresi dolunca çöp kutusuna gider, hatırlatması kalkar', () async {
      now = DateTime(2026, 12, 5, 0, 5);
      await service.runMaintenance();

      expect((await reload(item)).isDeleted, isTrue);
      expect(reminders.plans, isEmpty);
    });

    test('dolmadan önceki gün silinmez', () async {
      now = DateTime(2026, 12, 4, 23);
      await service.runMaintenance();

      expect((await reload(item)).isDeleted, isFalse);
    });

    test('30 gün sonra çöp kutusundan da silinir', () async {
      await service.delete(item.id);
      now = now.add(const Duration(days: 31));
      await service.runMaintenance();

      expect(await repo.byId(item.id), isNull);
    });

    test('süreyi uzat sayacı bugünden başlatır', () async {
      now = DateTime(2026, 12, 1, 9);
      await service.extend([item.id]);

      expect((await reload(item)).anchorDay, DateTime(2026, 12, 1));
      now = DateTime(2026, 12, 5, 0, 5);
      await service.runMaintenance();
      expect((await reload(item)).isDeleted, isFalse);
    });

    test('tarihi elle değiştirmek sayacı yeni tarihten başlatır', () async {
      final loaded = await reload(item);
      await service.save(loaded.movedTo(DateTime(2026, 11, 28), rolledBy: 0));

      expect((await reload(item)).anchorDay, DateTime(2026, 11, 28));
    });

    test('yarına taşı sayacı sıfırlamaz', () async {
      await service.moveToTomorrow(item.id);

      final moved = await reload(item);
      expect(moved.day, DateTime(2026, 11, 21));
      expect(moved.anchorDay, DateTime(2026, 11, 20));
    });

    test('önemli işareti kaldırılınca sayaç bugünden başlar', () async {
      final loaded = await reload(item);
      await service.save(loaded.copyWith(important: true));

      now = DateTime(2026, 12, 10, 9);
      await service.runMaintenance();
      final important = await reload(item);
      expect(important.isDeleted, isFalse);

      await service.save(important.copyWith(important: false));

      expect((await reload(item)).anchorDay, DateTime(2026, 12, 10));
    });

    test('çöpten geri alınan görev bugüne gelir, sayacı sıfırlanır', () async {
      now = DateTime(2026, 12, 5, 0, 5);
      await service.runMaintenance();
      now = DateTime(2026, 12, 6, 9);
      await service.restore(item.id);

      final restored = await reload(item);
      expect(restored.isDeleted, isFalse);
      expect(restored.day, DateTime(2026, 12, 6));
      expect(restored.anchorDay, DateTime(2026, 12, 6));
    });

    test('kural kapalıyken silinmez', () async {
      await settings.save(const AppSettings(lifecycleEnabled: false));
      now = DateTime(2027, 1, 20, 9);
      await service.runMaintenance();

      expect((await reload(item)).isDeleted, isFalse);
    });

    test('otomatik taşıma kapalıyken görev yerinde kalır', () async {
      await settings.save(const AppSettings(autoRollover: false));
      now = DateTime(2026, 11, 22, 9);
      await service.runMaintenance();

      expect((await reload(item)).day, DateTime(2026, 11, 20));
    });
  });

  group('durum değişiklikleri', () {
    test('tamamlama hatırlatmayı kaldırır, geri alma getirir', () async {
      final item = await service.create(
        title: 'Dişçi',
        day: DateTime(2026, 11, 21),
        start: DateTime(2026, 11, 21, 14),
        reminderMin: 15,
      );

      await service.toggleDone(item.id);
      expect((await reload(item)).isDone, isTrue);
      expect(reminders.plans, isEmpty);

      await service.toggleDone(item.id);
      expect((await reload(item)).isDone, isFalse);
      expect(itemPlans(), hasLength(1));
    });

    test('tamamlanan görev taşınmaz', () async {
      final item = await service.create(
        title: 'Market',
        day: DateTime(2026, 11, 20),
      );
      await service.complete(item.id);
      now = DateTime(2026, 11, 22, 9);
      await service.runMaintenance();

      expect((await reload(item)).day, DateTime(2026, 11, 20));
    });

    test('erteleme 10 dk sonraya bildirim planlar', () async {
      final item = await service.create(
        title: 'Dişçi',
        day: DateTime(2026, 11, 20),
        start: DateTime(2026, 11, 20, 10, 5),
        reminderMin: 15,
      );
      await service.snooze(item.id);

      expect(itemPlans().single.when, DateTime(2026, 11, 20, 10, 10));
    });

    test('silmeyi geri al', () async {
      final item = await service.create(
        title: 'Market',
        day: DateTime(2026, 11, 20),
      );
      final before = await reload(item);
      await service.delete(item.id);
      await service.undoDelete(before);

      expect((await reload(item)).isDeleted, isFalse);
    });

    test('kalıcı silme hatırlatma kaydını da kaldırır', () async {
      final item = await service.create(
        title: 'Dişçi',
        day: DateTime(2026, 11, 21),
        start: DateTime(2026, 11, 21, 14),
        reminderMin: 15,
      );
      await service.deleteForever(item.id);

      expect(await repo.byId(item.id), isNull);
      expect(await db.select(db.reminders).get(), isEmpty);
    });
  });

  group('ItemRepository', () {
    test('gün sorgusu saatli ve saatsiz girdileri getirir', () async {
      final day = DateTime(2026, 11, 21);
      await service.create(title: 'Saatsiz', day: day);
      await service.create(
        title: 'Saatli',
        day: day,
        start: DateTime(2026, 11, 21, 23, 30),
      );
      await service.create(title: 'Başka gün', day: DateTime(2026, 11, 22));

      final items = await repo.watchDays(day, day).first;

      expect(items.map((i) => i.title), unorderedEquals(['Saatsiz', 'Saatli']));
    });

    test('gecikmiş görevler yalnızca istenince gelir', () async {
      await service.create(title: 'Eski', day: DateTime(2026, 11, 15));
      final today = DateTime(2026, 11, 20);

      expect(await repo.watchDays(today, today).first, isEmpty);
      expect(
        await repo.watchDays(today, today, overdueBefore: today).first,
        hasLength(1),
      );
    });

    test('silinenler listede görünmez, çöpte görünür', () async {
      final day = DateTime(2026, 11, 20);
      final item = await service.create(title: 'Market', day: day);
      await service.delete(item.id);

      expect(await repo.watchDays(day, day).first, isEmpty);
      expect(await repo.watchTrash().first, hasLength(1));
    });
  });

  test('ertelenen planlama kısa sürede tek seferde yapılır', () async {
    var calls = 0;
    final deferred = ItemService(
      store: repo,
      settings: settings,
      reminders: _Counting(() => calls++),
      newId: () => 'id${nextId++}',
      deferReplan: true,
      clock: () => now,
    );
    final day = DateTime(2026, 11, 20);

    await deferred.create(title: 'Bir', day: day);
    await deferred.create(title: 'İki', day: day);
    expect(calls, 0);

    await deferred.flushReplan();
    expect(calls, 1);

    await deferred.flushReplan();
    expect(calls, 1);
    deferred.dispose();
  });

  test('bakım çok görevi tek işlemde yazar', () async {
    for (var i = 0; i < 3; i++) {
      await service.create(title: 'Görev $i', day: DateTime(2026, 11, 20));
    }
    now = DateTime(2026, 11, 21, 9);

    final refreshes = <int>[];
    final sub = repo
        .watchDays(DateTime(2026, 11, 21), DateTime(2026, 11, 21))
        .listen((items) => refreshes.add(items.length));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await service.runMaintenance();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(refreshes, [0, 3]);
  });

  test('bakım istenince alarmları yeniden kurar', () async {
    await service.runMaintenance();
    expect(reminders.rearmed, isFalse);

    await service.runMaintenance(rearm: true);
    expect(reminders.rearmed, isTrue);
  });

  test('ayarlar kaydedilir ve varsayılanlarla okunur', () async {
    expect((await settings.load()).lifecycleTtlDays, 15);

    await settings.save(
      const AppSettings(lifecycleTtlDays: 30, weekStart: DateTime.sunday),
    );

    final loaded = await settings.load();
    expect(loaded.lifecycleTtlDays, 30);
    expect(loaded.weekStart, DateTime.sunday);
    expect(loaded.autoRollover, isTrue);
  });
}
