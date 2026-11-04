import 'package:ajandam/data/db/app_database.dart';
import 'package:ajandam/data/repositories/item_repository.dart';
import 'package:ajandam/data/repositories/settings_repository.dart';
import 'package:ajandam/domain/item.dart';
import 'package:ajandam/domain/item_service.dart';
import 'package:ajandam/domain/recurrence.dart';
import 'package:ajandam/domain/reminder_planner.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _Reminders implements ReminderGateway {
  List<PlannedNotification> plans = [];

  @override
  Future<void> replaceAll(
    List<PlannedNotification> next, {
    bool rearm = false,
  }) async => plans = next;
}

void main() {
  group('Recurrence', () {
    // 20 Kasım 2026 cuma.
    final first = DateTime(2026, 11, 20);

    List<DateTime> days(Recurrence rule, DateTime from, DateTime to) =>
        rule.daysIn(first, from, to).toList();

    test('her gün ve iki günde bir', () {
      expect(
        days(const Recurrence(Frequency.daily), first, DateTime(2026, 11, 22)),
        [first, DateTime(2026, 11, 21), DateTime(2026, 11, 22)],
      );
      expect(
        days(
          const Recurrence(Frequency.daily, interval: 2),
          first,
          DateTime(2026, 11, 24),
        ),
        [first, DateTime(2026, 11, 22), DateTime(2026, 11, 24)],
      );
    });

    test('hafta içi hafta sonunu atlar', () {
      const rule = Recurrence(Frequency.weekly, weekdays: weekdaysMonFri);
      expect(days(rule, first, DateTime(2026, 11, 24)), [
        first,
        DateTime(2026, 11, 23),
        DateTime(2026, 11, 24),
      ]);
    });

    test('iki haftada bir salı ve cuma', () {
      const rule = Recurrence(
        Frequency.weekly,
        interval: 2,
        weekdays: {DateTime.tuesday, DateTime.friday},
      );
      expect(days(rule, first, DateTime(2026, 12, 5)), [
        first,
        DateTime(2026, 12, 1),
        DateTime(2026, 12, 4),
      ]);
    });

    test('bitiş günü dahildir', () {
      final rule = Recurrence(Frequency.weekly, until: DateTime(2026, 12, 4));
      expect(days(rule, first, DateTime(2027)), [
        first,
        DateTime(2026, 11, 27),
        DateTime(2026, 12, 4),
      ]);
    });

    test('ayın 31i olmayan aylar atlanır', () {
      final start = DateTime(2027, 1, 31);
      final rule = const Recurrence(Frequency.monthly);
      expect(rule.daysIn(start, start, DateTime(2027, 5, 31)).toList(), [
        start,
        DateTime(2027, 3, 31),
        DateTime(2027, 5, 31),
      ]);
    });

    test('her yıl', () {
      final start = DateTime(2027, 3, 12);
      expect(
        const Recurrence(Frequency.yearly)
            .daysIn(start, DateTime(2028), DateTime(2028, 12, 31))
            .toList(),
        [DateTime(2028, 3, 12)],
      );
    });

    test('RRULE olarak saklanır ve geri okunur', () {
      final rule = Recurrence(
        Frequency.weekly,
        interval: 2,
        weekdays: const {DateTime.friday, DateTime.tuesday},
        until: DateTime(2027, 3, 14),
      );
      expect(
        rule.toRrule(),
        'FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,FR;UNTIL=20270314',
      );
      expect(Recurrence.parse(rule.toRrule()), rule);
    });

    test('ilk gün tekrar günlerinden birine kayar', () {
      const rule = Recurrence(Frequency.weekly, weekdays: {DateTime.monday});
      expect(rule.align(first), DateTime(2026, 11, 23));
    });
  });

  group('seriler', () {
    late AppDatabase db;
    late ItemRepository repo;
    late _Reminders reminders;
    late ItemService service;
    late DateTime now;
    var nextId = 0;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ItemRepository(db);
      reminders = _Reminders();
      now = DateTime(2026, 11, 20, 10);
      service = ItemService(
        store: repo,
        settings: SettingsRepository(db),
        reminders: reminders,
        newId: () => 'id${nextId++}',
        clock: () => now,
      );
    });
    tearDown(() => db.close());

    Future<List<AgendaItem>> week() async =>
        (await repo.itemsAround(DateTime(2026, 11, 20), DateTime(2026, 11, 26)))
          ..sort((a, b) => a.day.compareTo(b.day));

    Future<AgendaItem> daily() => service.create(
      title: 'İlaç',
      day: DateTime(2026, 11, 20),
      start: DateTime(2026, 11, 20, 21),
      reminderMin: 0,
      recurrence: const Recurrence(Frequency.daily),
    );

    test('seri her gününde görünür, kendisi görünmez', () async {
      final series = await daily();
      final items = await week();

      expect(items, hasLength(7));
      expect(items.map((i) => i.seriesId).toSet(), {series.id});
      expect(items.last.start, DateTime(2026, 11, 26, 21));
      expect(items.first.recurrence, const Recurrence(Frequency.daily));
    });

    test('haftalık seri ilk uygun güne kayar', () async {
      final series = await service.create(
        title: 'Spor',
        day: DateTime(2026, 11, 20),
        start: DateTime(2026, 11, 20, 18),
        durationMin: 90,
        recurrence: const Recurrence(
          Frequency.weekly,
          weekdays: {DateTime.tuesday, DateTime.thursday},
        ),
      );

      expect(series.day, DateTime(2026, 11, 24));
      expect(series.kind, ItemKind.event);
      expect((await week()).map((i) => i.day), [
        DateTime(2026, 11, 24),
        DateTime(2026, 11, 26),
      ]);
    });

    test('tekrarı tamamlamak yalnızca o günü değiştirir', () async {
      await daily();
      final today = (await week()).first;
      await service.toggleDone(today.id);

      final items = await week();
      expect(items, hasLength(7));
      expect(items.where((i) => i.isDone).map((i) => i.day), [
        DateTime(2026, 11, 20),
      ]);
    });

    test('kaçırılan tekrar ertesi güne taşınmaz ve silinmez', () async {
      await daily();
      now = DateTime(2026, 12, 20, 10);
      await service.runMaintenance();

      final items = await repo.itemsAround(
        DateTime(2026, 11, 20),
        DateTime(2026, 11, 20),
      );
      expect(items.single.day, DateTime(2026, 11, 20));
      expect(items.single.isDeleted, isFalse);
      expect(
        await repo.itemsAround(DateTime(2026, 12, 20), DateTime(2026, 12, 20)),
        hasLength(1),
      );
    });

    test('tekrar hatırlatmaları kurulur', () async {
      await daily();
      final plans = reminders.plans
          .where((p) => p.type == NotificationType.item)
          .toList();

      expect(plans.first.when, DateTime(2026, 11, 20, 21));
      expect(plans, hasLength(occurrenceDays + 1));
    });

    test('yalnızca bu tekrarı silmek', () async {
      await daily();
      final second = (await week())[1];
      await service.delete(second.id);

      expect((await week()).map((i) => i.day), isNot(contains(second.day)));
      expect(await repo.watchTrash().first, isEmpty);
    });

    test('bu ve sonrakileri silmek geçmişi korur', () async {
      final series = await daily();
      await service.toggleDone((await week()).first.id);
      final third = (await week())[2];
      await service.deleteFollowing(third);

      final items = await week();
      expect(items.map((i) => i.day), [
        DateTime(2026, 11, 20),
        DateTime(2026, 11, 21),
      ]);
      expect(items.first.isDone, isTrue);
      expect(
        (await repo.byId(series.id))!.recurrence!.until,
        DateTime(2026, 11, 21),
      );
    });

    test('ilk tekrardan itibaren silmek seriyi çöpe atar', () async {
      final series = await daily();
      await service.deleteFollowing((await week()).first);

      expect(await week(), isEmpty);
      expect((await repo.watchTrash().first).single.id, series.id);
      await service.restore(series.id);
      expect(await week(), hasLength(7));
    });

    test('yalnızca bu tekrarı düzenlemek', () async {
      await daily();
      final second = (await week())[1];
      await service.save(
        second.copyWith(
          title: 'İlaç (yarım doz)',
          start: DateTime(2026, 11, 21, 22),
        ),
      );

      final items = await week();
      expect(items, hasLength(7));
      expect(items[1].title, 'İlaç (yarım doz)');
      expect(items[1].start, DateTime(2026, 11, 21, 22));
      expect(items[2].title, 'İlaç');
    });

    test('bu ve sonrakileri düzenlemek seriyi böler', () async {
      final series = await daily();
      final third = (await week())[2];
      await service.saveFollowing(
        third.copyWith(start: DateTime(2026, 11, 22, 8)),
      );

      final items = await week();
      expect(items, hasLength(7));
      expect(items.map((i) => i.start!.hour), [21, 21, 8, 8, 8, 8, 8]);
      expect(items[2].seriesId, isNot(series.id));
    });

    test('ilk tekrardan düzenlemek seriyi değiştirir', () async {
      final series = await daily();
      await service.saveFollowing(
        (await week()).first.copyWith(
          title: 'Vitamin',
          recurrence: const Recurrence(Frequency.daily, interval: 2),
        ),
      );

      final items = await week();
      expect(items.map((i) => i.day.day), [20, 22, 24, 26]);
      expect(items.map((i) => i.seriesId).toSet(), {series.id});
      expect(items.first.title, 'Vitamin');
    });

    test('kalıcı silinen seri tekrar kayıtlarını da götürür', () async {
      final series = await daily();
      await service.toggleDone((await week()).first.id);
      await service.deleteFollowing((await week()).first);
      await service.deleteForever(series.id);

      expect(await db.select(db.items).get(), isEmpty);
    });
  });

  group('birkaç günlük etkinlik', () {
    late AppDatabase db;
    late ItemRepository repo;
    late ItemService service;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ItemRepository(db);
      service = ItemService(
        store: repo,
        settings: SettingsRepository(db),
        reminders: _Reminders(),
        newId: () => 'tatil',
        clock: () => DateTime(2026, 11, 2, 10),
      );
    });
    tearDown(() => db.close());

    test('her gününde görünür ve bitince biter', () async {
      final item = await service.create(
        title: 'Tatil',
        day: DateTime(2026, 11, 5),
        endDay: DateTime(2026, 11, 10),
      );

      expect(item.kind, ItemKind.event);
      final items = await repo.itemsAround(
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 8),
      );
      expect(items.map((i) => i.day.day), [5, 6, 7, 8]);
      expect(item.isFinished(DateTime(2026, 11, 10, 23)), isFalse);
      expect(item.isFinished(DateTime(2026, 11, 11)), isTrue);
    });
  });
}
