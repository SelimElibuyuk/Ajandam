import 'package:ajandam/domain/item.dart';
import 'package:ajandam/domain/reminder_planner.dart';
import 'package:ajandam/domain/rollover.dart';
import 'package:ajandam/domain/task_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

AgendaItem task(
  String id, {
  required DateTime day,
  DateTime? start,
  DateTime? anchor,
  int? reminderMin,
  bool important = false,
  DateTime? doneAt,
}) => AgendaItem(
  id: id,
  kind: ItemKind.task,
  title: 'Görev $id',
  day: day,
  start: start,
  anchorDay: anchor ?? day,
  reminderMin: reminderMin,
  important: important,
  doneAt: doneAt,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('rollover', () {
    test('kaçırılan gün sayısı kadar sayar', () {
      final moved = rollover(
        task('1', day: DateTime(2026, 11, 1)),
        DateTime(2026, 11, 3),
      );

      expect(moved!.day, DateTime(2026, 11, 3));
      expect(moved.rolledCount, 2);
    });

    test('saatli görev aynı saatiyle taşınır', () {
      final moved = rollover(
        task(
          '1',
          day: DateTime(2026, 11, 2),
          start: DateTime(2026, 11, 2, 14, 30),
        ),
        DateTime(2026, 11, 3),
      );

      expect(moved!.start, DateTime(2026, 11, 3, 14, 30));
    });

    test('sayaç başlangıcı taşımayla değişmez', () {
      final moved = rollover(
        task('1', day: DateTime(2026, 11, 2)),
        DateTime(2026, 11, 3),
      );

      expect(moved!.anchorDay, DateTime(2026, 11, 2));
    });

    test('tamamlanan, gelecek ve etkinlik taşınmaz', () {
      final today = DateTime(2026, 11, 3);
      expect(
        rollover(
          task('1', day: DateTime(2026, 11, 2), doneAt: DateTime(2026, 11, 2)),
          today,
        ),
        isNull,
      );
      expect(rollover(task('2', day: today), today), isNull);
      expect(
        rollover(
          task('3', day: DateTime(2026, 11, 2)).copyWith(kind: ItemKind.event),
          today,
        ),
        isNull,
      );
    });
  });

  group('LifecycleRule', () {
    const rule = LifecycleRule();
    final item = task('1', day: DateTime(2026, 11, 20));

    test('PRD örneği: 22 Kasım-4 Aralık hatırlatma, 5 Aralıkta silme', () {
      final days = rule.reminderDays(item);

      expect(days.first, DateTime(2026, 11, 22));
      expect(days.last, DateTime(2026, 12, 4));
      expect(days, hasLength(7));
      expect(rule.expiryDay(item), DateTime(2026, 12, 5));
      expect(rule.daysLeft(item, DateTime(2026, 11, 22)), 13);
      expect(rule.isExpired(item, DateTime(2026, 12, 4)), isFalse);
      expect(rule.isExpired(item, DateTime(2026, 12, 5)), isTrue);
    });

    test('önemli, tamamlanan ve etkinlik muaf', () {
      final late = DateTime(2027);
      expect(
        rule.isExpired(
          task('1', day: DateTime(2026, 11, 20), important: true),
          late,
        ),
        isFalse,
      );
      expect(
        rule.isExpired(item.copyWith(doneAt: DateTime(2026, 11, 21)), late),
        isFalse,
      );
      expect(
        rule.isExpired(
          item.copyWith(kind: ItemKind.event, anchorDay: null),
          late,
        ),
        isFalse,
      );
    });

    test('kapalıyken uygulanmaz', () {
      const off = LifecycleRule(enabled: false);
      expect(off.isExpired(item, DateTime(2027)), isFalse);
    });
  });

  group('planNotifications', () {
    final now = DateTime(2026, 11, 3, 10);
    const rule = LifecycleRule(enabled: false);

    test('başlangıçtan önce hatırlatır', () {
      final plans = planNotifications(
        [
          task(
            '1',
            day: DateTime(2026, 11, 4),
            start: DateTime(2026, 11, 4, 10),
            reminderMin: 15,
          ),
        ],
        rule,
        now,
      );

      expect(plans.single.when, DateTime(2026, 11, 4, 9, 45));
      expect(plans.single.body, '10:00 · 15 dk sonra');
    });

    test('geçmiş, hatırlatmasız ve tamamlanmış plan edilmez', () {
      final day = DateTime(2026, 11, 3);
      final plans = planNotifications(
        [
          task('1', day: day, start: DateTime(2026, 11, 3, 9), reminderMin: 15),
          task('2', day: day, start: DateTime(2026, 11, 3, 12)),
          task(
            '3',
            day: day,
            start: DateTime(2026, 11, 3, 12),
            reminderMin: 15,
            doneAt: now,
          ),
        ],
        rule,
        now,
      );

      expect(plans, isEmpty);
    });

    test('ertelenen görev ertelenen saatte gelir', () {
      final snoozed = task(
        '1',
        day: DateTime(2026, 11, 3),
        start: DateTime(2026, 11, 3, 10, 5),
        reminderMin: 15,
      ).copyWith(snoozedUntil: DateTime(2026, 11, 3, 10, 10));

      final plans = planNotifications([snoozed], rule, now);

      expect(plans.single.when, DateTime(2026, 11, 3, 10, 10));
    });

    test('görev ömrü hatırlatması kalan süreyi yazar', () {
      final plans = planNotifications(
        [task('1', day: DateTime(2026, 11, 20))],
        const LifecycleRule(),
        now,
      );

      expect(plans.first.when, DateTime(2026, 11, 22, 9));
      expect(plans.first.body, 'Silinmesine 13 gün kaldı');
      expect(plans.first.type, NotificationType.lifecycle);
      expect(plans, hasLength(7));
    });

    test('aynı gün birden çok görev tek bildirimde toplanır', () {
      final plans = planNotifications(
        [
          task('1', day: DateTime(2026, 11, 20)),
          task('2', day: DateTime(2026, 11, 20)),
        ],
        const LifecycleRule(),
        now,
      );

      expect(plans, hasLength(7));
      expect(plans.first.type, NotificationType.lifecycleGroup);
      expect(plans.first.title, '2 görev silinmeye yaklaşıyor');
      expect(plans.first.itemIds, ['1', '2']);
    });

    test('kimlik aynı plan için sabit kalır', () {
      final item = task(
        '1',
        day: DateTime(2026, 11, 4),
        start: DateTime(2026, 11, 4, 10),
        reminderMin: 15,
      );

      expect(
        planNotifications([item], rule, now).single.key,
        planNotifications([item], rule, now).single.key,
      );
    });

    test('sınırı aşmaz, en yakınları tutar', () {
      final items = [
        for (var i = 1; i <= 300; i++)
          task(
            '$i',
            day: DateTime(2026, 11, 4),
            start: DateTime(2026, 11, 4).add(Duration(minutes: i)),
            reminderMin: 0,
          ),
      ];

      final plans = planNotifications(items, rule, now);

      expect(plans, hasLength(maxPlanned));
      expect(plans.last.itemIds, ['$maxPlanned']);
    });
  });

  test('offsetLabel', () {
    expect(offsetLabel(15), '15 dk');
    expect(offsetLabel(60), '1 saat');
    expect(offsetLabel(1440), '1 gün');
    expect(offsetLabel(90), '90 dk');
  });
}
