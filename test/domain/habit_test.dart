import 'dart:convert';

import 'package:ajandam/data/db/app_database.dart';
import 'package:ajandam/data/repositories/habit_repository.dart';
import 'package:ajandam/data/repositories/settings_repository.dart';
import 'package:ajandam/domain/habit.dart';
import 'package:ajandam/domain/habit_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 2026-11-20 cuma.
final _today = DateTime(2026, 11, 20);

Habit _habit({Set<int> weekdays = const {}, int? target}) => Habit(
  id: 'h',
  title: 'Su',
  weekdays: weekdays,
  target: target,
  startDay: DateTime(2026, 11, 1),
  createdAt: DateTime(2026, 11, 1),
  updatedAt: DateTime(2026, 11, 1),
);

Map<DateTime, int> _days(List<int> days, [int count = 1]) => {
  for (final d in days) DateTime(2026, 11, d): count,
};

class _FakeWidget implements HabitWidgetGateway {
  String? snapshot;
  List<HabitAction> pending = [];

  @override
  Future<void> publishHabits(String snapshot) async => this.snapshot = snapshot;

  @override
  Future<List<HabitAction>> takeHabitActions() async {
    final taken = pending;
    pending = [];
    return taken;
  }
}

void main() {
  group('seri', () {
    test('art arda yapılan günler sayılır, bugün yapılmadıysa dünden', () {
      final history = HabitHistory(_habit(), _days([17, 18, 19]));
      expect(history.streak(_today), 3);
      expect(HabitHistory(_habit(), _days([17, 18, 19, 20])).streak(_today), 4);
    });

    test('kaçırılan gün seriyi bozar', () {
      final history = HabitHistory(_habit(), _days([14, 15, 16, 18, 19]));
      expect(history.streak(_today), 2);
      expect(history.longestStreak(_today), 3);
    });

    test('planlanmamış günler seriyi bozmaz', () {
      // Hafta içi: 14-15 kasım hafta sonu.
      final habit = _habit(weekdays: {1, 2, 3, 4, 5});
      final history = HabitHistory(habit, _days([12, 13, 16, 17, 18, 19]));
      expect(history.streak(_today), 6);
    });

    test('sayılı alışkanlık hedefe ulaşınca yapılmış sayılır', () {
      final habit = _habit(target: 8);
      final history = HabitHistory(habit, {
        ..._days([18], 8),
        ..._days([19], 3),
      });
      expect(history.doneOn(DateTime(2026, 11, 18)), isTrue);
      expect(history.doneOn(DateTime(2026, 11, 19)), isFalse);
      expect(history.streak(_today), 0);
    });

    test('oran bugün yapılmadıysa bugünü saymaz', () {
      final history = HabitHistory(_habit(), _days([17, 19]));
      // 1-19 kasım: 19 planlı gün, 2 yapıldı.
      expect(history.rate(_today), closeTo(2 / 19, 0.001));
      expect(
        HabitHistory(_habit(), const {}).rate(DateTime(2026, 11, 1)),
        isNull,
      );
    });

    test('dokunuş hedefe kadar artırır, hedefte sıfırlar', () {
      expect(_habit().tapped(0), 1);
      expect(_habit().tapped(1), 0);
      final counted = _habit(target: 3);
      expect([0, 1, 2, 3].map(counted.tapped), [1, 2, 3, 0]);
    });

    test('gün etiketi', () {
      expect(habitDaysLabel(const {}), 'Her gün');
      expect(habitDaysLabel(const {1, 2, 3, 4, 5}), 'Hafta içi');
      expect(habitDaysLabel(const {6, 7}), 'Hafta sonu');
      expect(habitDaysLabel(const {5, 1}), 'Pzt, Cum');
    });
  });

  group('servis', () {
    late AppDatabase db;
    late HabitRepository repo;
    late _FakeWidget widget;
    late HabitService service;
    var now = DateTime(2026, 11, 20, 9);
    var nextId = 0;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = HabitRepository(db);
      widget = _FakeWidget();
      now = DateTime(2026, 11, 20, 9);
      service = HabitService(
        store: repo,
        settings: SettingsRepository(db),
        newId: () => 'h${nextId++}',
        widget: widget,
        clock: () => now,
      );
    });
    tearDown(() => db.close());

    test('oluşturma sıra ve renk verir, 7 gün her gün sayılır', () async {
      final a = await service.create(title: ' Su iç ', target: 8);
      final b = await service.create(
        title: 'Spor',
        weekdays: {1, 2, 3, 4, 5, 6, 7},
        target: 1,
      );

      final habits = await repo.habits();
      expect(habits.map((h) => h.title), ['Su iç', 'Spor']);
      expect(a.target, 8);
      expect(b.target, isNull);
      expect(b.weekdays, isEmpty);
      expect(habits.map((h) => h.color), [0, 1]);
      expect(habits.first.startDay, DateTime(2026, 11, 20));
    });

    test('dokunuş kaydedilir, gelecek gün işaretlenmez', () async {
      final habit = await service.create(title: 'Su', target: 2);
      expect(await service.tap(habit, _today, 0), 1);
      expect(await service.tap(habit, _today, 1), 2);
      expect(await service.tap(habit, DateTime(2026, 11, 21), 0), isNull);
      expect(await repo.history(habit.id), {_today: 2});

      await service.reset(habit, _today);
      expect(await repo.history(habit.id), isEmpty);
    });

    test('silme geçmişi de siler', () async {
      final habit = await service.create(title: 'Su');
      await service.tap(habit, _today, 0);
      await service.delete(habit.id);
      expect(await repo.habits(), isEmpty);
      expect(await repo.counts(DateTime(2026), DateTime(2027)), isEmpty);
    });

    test('widget dokunuşları mutlak sayıyla işlenir', () async {
      final habit = await service.create(title: 'Su', target: 8);
      widget.pending = [
        HabitAction(habitId: habit.id, day: _today, count: 3, at: now),
        HabitAction(habitId: habit.id, day: _today, count: 4, at: now),
        HabitAction(habitId: 'silinmiş', day: _today, count: 1, at: now),
      ];
      await service.applyWidgetActions();
      expect(await repo.history(habit.id), {_today: 4});
    });

    test('anlık görüntü pencereyi ve eski seriyi taşır', () async {
      final habit = await service.create(title: 'Su');
      // Pencere 17 ekim'de başlar; öncesi 3 gün yapıldı.
      for (final d in [
        DateTime(2026, 10, 14),
        DateTime(2026, 10, 15),
        DateTime(2026, 10, 16),
        DateTime(2026, 11, 19),
      ]) {
        await repo.setCount(habit.id, d, 1, now);
      }
      await service.publishWidget();

      final json = jsonDecode(widget.snapshot!) as Map<String, dynamic>;
      expect(json['windowStart'], '2026-10-17');
      final entry = (json['habits'] as List).single as Map<String, dynamic>;
      expect(entry['olderStreak'], 3);
      expect(entry['counts'], {'2026-11-19': 1});
      expect(entry['goal'], 1);
      expect(entry['weekdays'], isEmpty);
      expect(entry['color'], habitColors.first);
    });
  });
}
