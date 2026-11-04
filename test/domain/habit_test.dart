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

  group('dondurma', () {
    Map<DateTime, bool> frozen(List<int> days, [bool value = true]) => {
      for (final d in days) DateTime(2026, 11, d): value,
    };

    test('her 3 yapılan gün bir hak, en çok 2', () {
      final four = HabitHistory(_habit(), _days([1, 2, 3, 4]));
      expect(four.freezeRights(_today), (rights: 1, progress: 1));
      final nine = HabitHistory(_habit(), _days([1, 2, 3, 4, 5, 6, 7, 8, 9]));
      expect(nine.freezeRights(_today), (rights: 2, progress: 0));
    });

    test('dondurulan gün hak harcar, bozulan seri hakkı silmez', () {
      final used = HabitHistory(_habit(), _days([1, 2, 3]), frozen([4]));
      expect(used.freezeRights(_today).rights, 0);
      final earned = HabitHistory(
        _habit(),
        _days([1, 2, 3, 5, 6, 7]),
        frozen([4]),
      );
      expect(earned.freezeRights(_today).rights, 1);
      final broken = HabitHistory(
        _habit(),
        _days([1, 2, 3]),
        frozen([4], false),
      );
      expect(broken.freezeRights(_today).rights, 1);
      expect(broken.streak(_today), 0);
    });

    test('dondurulan gün seriyi korur ama sayılmaz', () {
      final history = HabitHistory(
        _habit(),
        _days([15, 16, 17, 19]),
        frozen([18]),
      );
      expect(history.frozenOn(DateTime(2026, 11, 18)), isTrue);
      expect(history.streak(_today), 4);
      expect(history.longestStreak(_today), 4);
      // 1-19 kasım: 18 planlı gün (dondurulan hariç), 4 yapıldı.
      expect(history.rate(_today), closeTo(4 / 18, 0.001));
      // Sonradan yapılırsa yapılmış sayılır.
      final done = HabitHistory(
        _habit(),
        _days([15, 16, 17, 18, 19]),
        frozen([18]),
      );
      expect(done.frozenOn(DateTime(2026, 11, 18)), isFalse);
      expect(done.streak(_today), 5);
    });

    test('dün kaçırıldıysa tek günlük teklif', () {
      final offer = HabitHistory(
        _habit(),
        _days([13, 14, 15, 16, 17, 18]),
      ).freezeOffer(_today)!;
      expect(offer.days, [DateTime(2026, 11, 19)]);
      expect(offer.streak, 6);
      expect(offer.rights, 2);
    });

    test('iki günlük boşluk iki hak ister', () {
      final offer = HabitHistory(
        _habit(),
        _days([12, 13, 14, 15, 16, 17]),
      ).freezeOffer(_today)!;
      expect(offer.days, [DateTime(2026, 11, 18), DateTime(2026, 11, 19)]);
      expect(offer.streak, 6);
    });

    test('hak yetmezse teklif yok', () {
      final history = HabitHistory(_habit(), _days([15, 16, 17]));
      expect(history.freezeRights(_today).rights, 1);
      expect(history.freezeOffer(_today), isNull);
      // Üç günlük boşluk hiçbir zaman.
      expect(
        HabitHistory(
          _habit(),
          _days([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]),
        ).freezeOffer(_today),
        isNull,
      );
    });

    test('karar verilmiş günler yeniden sorulmaz', () {
      final days = _days([13, 14, 15, 16, 17, 18]);
      expect(
        HabitHistory(_habit(), days, frozen([19], false)).freezeOffer(_today),
        isNull,
      );
      expect(
        HabitHistory(_habit(), days, frozen([19])).freezeOffer(_today),
        isNull,
      );
    });

    test('bugün kaçırılmış sayılmaz, bugünün hakkı boşluğa yetmez', () {
      expect(
        HabitHistory(_habit(), _days([17, 18, 19])).freezeOffer(_today),
        isNull,
      );
      // Dün kaçırıldı, bugün yapıldı: teklif hâlâ geçerli.
      final offer = HabitHistory(
        _habit(),
        _days([16, 17, 18, 20]),
      ).freezeOffer(_today)!;
      expect(offer.days, [DateTime(2026, 11, 19)]);
      expect(offer.rights, 1);
      // Bugün yapılan 3. gün hakkı boşluktan sonra kazanılır.
      expect(
        HabitHistory(_habit(), _days([17, 18, 20])).freezeOffer(_today),
        isNull,
      );
    });

    test('seri yoksa ya da başlangıçtan beri yapılmadıysa teklif yok', () {
      expect(HabitHistory(_habit(), const {}).freezeOffer(_today), isNull);
    });

    test('planlanmamış günler boşluğa girmez', () {
      // Hafta içi; 23 kasım pazartesi, 21-22 hafta sonu.
      final offer = HabitHistory(
        _habit(weekdays: {1, 2, 3, 4, 5}),
        _days([17, 18, 19]),
      ).freezeOffer(DateTime(2026, 11, 23))!;
      expect(offer.days, [DateTime(2026, 11, 20)]);
      expect(offer.streak, 3);
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
      expect(entry['frozen'], isEmpty);
    });

    Future<Habit> missedYesterday() async {
      final habit = await service.create(title: 'Su');
      for (final d in [16, 17, 18]) {
        await repo.setCount(habit.id, DateTime(2026, 11, d), 1, now);
      }
      return habit;
    }

    test('dondurma hakkı bir kez harcanır, widget bilgilenir', () async {
      final habit = await missedYesterday();
      final offer = (await service.freezeOffer(habit))!;
      expect(offer.days, [DateTime(2026, 11, 19)]);

      expect(await service.freeze(habit), isTrue);
      expect(await service.freeze(habit), isFalse);
      expect(await repo.freezeDecisions(habit.id), {
        DateTime(2026, 11, 19): true,
      });
      final history = HabitHistory(
        habit,
        await repo.history(habit.id),
        await repo.freezeDecisions(habit.id),
      );
      expect(history.streak(_today), 3);
      expect(history.freezeRights(_today).rights, 0);

      final json = jsonDecode(widget.snapshot!) as Map<String, dynamic>;
      final entry = (json['habits'] as List).single as Map<String, dynamic>;
      expect(entry['frozen'], ['2026-11-19']);
    });

    test('reddedilen günler bir daha sorulmaz', () async {
      final habit = await missedYesterday();
      expect(await service.declineFreeze(habit), isTrue);
      expect(await service.freezeOffer(habit), isNull);
      expect(await repo.freezeDecisions(habit.id), {
        DateTime(2026, 11, 19): false,
      });
      expect(await repo.frozenDays(DateTime(2026), DateTime(2027)), isEmpty);
    });

    test('silme dondurma kararlarını da siler', () async {
      final habit = await missedYesterday();
      await service.freeze(habit);
      await service.delete(habit.id);
      expect(await db.select(db.habitFreezes).get(), isEmpty);
    });

    test('eski seri pencere dışındaki dondurulan günden geçer', () async {
      final habit = await service.create(title: 'Su');
      // Pencere 17 ekim'de başlar; 16 ekim donduruldu.
      for (final d in [13, 14, 15]) {
        await repo.setCount(habit.id, DateTime(2026, 10, d), 1, now);
      }
      await repo.decideFreeze(habit.id, [DateTime(2026, 10, 16)], true);
      await repo.decideFreeze(habit.id, [DateTime(2026, 11, 18)], true);
      await service.publishWidget();

      final json = jsonDecode(widget.snapshot!) as Map<String, dynamic>;
      final entry = (json['habits'] as List).single as Map<String, dynamic>;
      expect(entry['olderStreak'], 3);
      expect(entry['frozen'], ['2026-11-18']);
    });
  });
}
