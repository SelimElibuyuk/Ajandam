import 'package:ajandam/data/db/app_database.dart';
import 'package:ajandam/data/repositories/item_repository.dart';
import 'package:ajandam/data/repositories/settings_repository.dart';
import 'package:ajandam/domain/item.dart';
import 'package:ajandam/domain/item_service.dart';
import 'package:ajandam/domain/reminder_planner.dart';
import 'package:ajandam/domain/settings.dart';
import 'package:ajandam/domain/task_lifecycle.dart';
import 'package:ajandam/domain/untimed_reminder.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AgendaItem task(
  String id, {
  required DateTime day,
  String? title,
  DateTime? start,
  int? reminderMin,
  DateTime? doneAt,
  DateTime? deletedAt,
  ItemKind kind = ItemKind.task,
}) => AgendaItem(
  id: id,
  kind: kind,
  title: title ?? 'Görev $id',
  day: day,
  start: start,
  reminderMin: reminderMin,
  doneAt: doneAt,
  deletedAt: deletedAt,
  createdAt: DateTime(2026, 1, 1, 0, int.tryParse(id) ?? 0),
  updatedAt: DateTime(2026),
);

class _Reminders implements ReminderGateway {
  List<PlannedNotification> plans = [];

  @override
  Future<void> replaceAll(
    List<PlannedNotification> next, {
    bool rearm = false,
  }) async => plans = next;
}

void main() {
  const off = LifecycleRule(enabled: false);
  final now = DateTime(2026, 11, 9, 10);
  final tomorrow = DateTime(2026, 11, 10);

  List<PlannedNotification> plan(
    List<AgendaItem> items, {
    int untimedDefault = untimedEveningDefault,
    DateTime? at,
  }) => planNotifications(
    items,
    off,
    at ?? now,
    untimedDefault: untimedDefault,
  ).where((p) => p.type == NotificationType.untimed).toList();

  group('kodlama', () {
    test('önceki akşam ve aynı gün dakikası', () {
      expect(untimedOffset(UntimedMode.eveningBefore, 20 * 60), -240);
      expect(untimedOffset(UntimedMode.sameDay, 8 * 60), 480);
      expect(untimedModeOf(-240), UntimedMode.eveningBefore);
      expect(untimedModeOf(480), UntimedMode.sameDay);
      expect(untimedModeOf(untimedReminderOff), UntimedMode.off);
      expect(untimedMinuteOfDay(-240), 20 * 60);
      expect(untimedReminderTime(tomorrow, -240), DateTime(2026, 11, 9, 20));
      expect(untimedReminderTime(tomorrow, 480), DateTime(2026, 11, 10, 8));
      expect(untimedReminderTime(tomorrow, untimedReminderOff), isNull);
    });
  });

  group('saatsiz görev hatırlatması', () {
    test('varsayılan: önceki akşam 20:00, tek görev', () {
      final plans = plan([task('1', day: tomorrow, title: 'Raporu gönder')]);

      expect(plans.single.when, DateTime(2026, 11, 9, 20));
      expect(plans.single.title, 'Yarın: Raporu gönder');
      expect(plans.single.day, tomorrow);
      expect(plans.single.itemIds, ['1']);
      expect(plans.single.lines, isEmpty);
    });

    test('aynı ana düşen görevler tek bildirimde toplanır', () {
      final plans = plan([
        task('1', day: tomorrow, title: 'Raporu gönder'),
        task('2', day: tomorrow, title: 'Market'),
        // Özel ama aynı an: önceki akşam 20:00 açıkça seçilmiş.
        task('3', day: tomorrow, title: 'Faturayı öde', reminderMin: -240),
      ]);

      expect(plans, hasLength(1));
      expect(plans.single.title, 'Yarın 3 görev');
      expect(plans.single.body, 'Raporu gönder, Market, Faturayı öde');
      expect(plans.single.lines, ['Raporu gönder', 'Market', 'Faturayı öde']);
      expect(plans.single.itemIds, ['1', '2', '3']);
    });

    test('özel ayar varsayılandan ayrı ana kurulur', () {
      final plans = plan([
        task('1', day: tomorrow),
        task('2', day: tomorrow, reminderMin: 480),
        task('3', day: tomorrow, reminderMin: -180),
      ]);

      expect(
        [for (final p in plans) p.when],
        [
          DateTime(2026, 11, 9, 20),
          DateTime(2026, 11, 9, 21),
          DateTime(2026, 11, 10, 8),
        ],
      );
      expect(plans.last.title, 'Bugün: Görev 2');
    });

    test('ayarda varsayılan sabah seçilirse sabah gelir', () {
      final plans = plan([
        task('1', day: tomorrow),
      ], untimedDefault: untimedMorningDefault);

      expect(plans.single.when, DateTime(2026, 11, 10, 8));
      expect(plans.single.title, 'Bugün: Görev 1');
    });

    test('kapalı: görevde veya ayarda', () {
      expect(
        plan([task('1', day: tomorrow, reminderMin: untimedReminderOff)]),
        isEmpty,
      );
      expect(
        plan([task('1', day: tomorrow)], untimedDefault: untimedReminderOff),
        isEmpty,
      );
      // Ayar kapalı olsa da görevde seçilen kurulur.
      expect(
        plan([
          task('1', day: tomorrow, reminderMin: 480),
        ], untimedDefault: untimedReminderOff),
        hasLength(1),
      );
    });

    test('tamamlanan, silinen, saatli ve etkinlik dahil edilmez', () {
      final plans = plan([
        task('1', day: tomorrow, doneAt: now),
        task('2', day: tomorrow, deletedAt: now),
        task('3', day: tomorrow, start: DateTime(2026, 11, 10, 9)),
        task('4', day: tomorrow, kind: ItemKind.event),
      ]);

      expect(plans, isEmpty);
    });

    test('geçmişte kalan an kurulmaz', () {
      final today = DateTime(2026, 11, 9);
      // Bugünkü görevin önceki akşamı ve sabahı (10:00'dan önce) geçti.
      expect(plan([task('1', day: today)]), isEmpty);
      expect(plan([task('2', day: today, reminderMin: 480)]), isEmpty);
      expect(
        plan([task('3', day: today, reminderMin: 12 * 60)]).single.when,
        DateTime(2026, 11, 9, 12),
      );
    });

    test('gece taşınan görev geçmiş hatırlatma kurmaz', () {
      final rolled = task(
        '1',
        day: DateTime(2026, 11, 8),
      ).movedTo(DateTime(2026, 11, 9), rolledBy: 1);

      expect(plan([rolled], at: DateTime(2026, 11, 9, 0, 5)), isEmpty);
    });

    test('bugün ve yarın aynı ana düşerse ikisi de yazılır', () {
      final plans = plan([
        task('1', day: tomorrow, title: 'A'),
        task('2', day: DateTime(2026, 11, 9), title: 'B', reminderMin: 1200),
      ]);

      expect(plans.single.title, '2 görev');
      expect(plans.single.lines, ['B (Bugün)', 'A (Yarın)']);
      expect(plans.single.day, DateTime(2026, 11, 9));
    });

    test('kimlik aynı plan için sabit, içerik değişince değişir', () {
      final a = plan([task('1', day: tomorrow)]).single.key;
      final b = plan([task('1', day: tomorrow)]).single.key;
      final c = plan([task('1', day: tomorrow, title: 'Başka')]).single.key;

      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('servis ve kayıt', () {
    late AppDatabase db;
    late _Reminders reminders;
    late ItemService service;
    late DateTime clock;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      reminders = _Reminders();
      clock = now;
      var next = 0;
      service = ItemService(
        store: ItemRepository(db),
        settings: SettingsRepository(db),
        reminders: reminders,
        newId: () => 'id${next++}',
        clock: () => clock,
      );
    });

    tearDown(() => db.close());

    List<PlannedNotification> untimed() => [
      for (final p in reminders.plans)
        if (p.type == NotificationType.untimed) p,
    ];

    test('yeni saatsiz görev varsayılanla önceki akşam hatırlatılır', () async {
      await service.create(title: 'Market', day: tomorrow);

      expect(untimed().single.when, DateTime(2026, 11, 9, 20));
    });

    test('görevdeki seçim kaydedilir ve geri okunur', () async {
      final item = await service.create(title: 'Market', day: tomorrow);
      await service.save(item.copyWith(reminderMin: untimedReminderOff));

      final saved = await ItemRepository(db).byId(item.id);
      expect(saved!.reminderMin, untimedReminderOff);
      expect(untimed(), isEmpty);

      await service.save(saved.copyWith(reminderMin: 450));
      expect(untimed().single.when, DateTime(2026, 11, 10, 7, 30));
    });

    test('ayardaki varsayılan saklanır ve planı değiştirir', () async {
      final settings = SettingsRepository(db);
      expect((await settings.load()).untimedReminderMin, untimedEveningDefault);

      await settings.save(
        const AppSettings(untimedReminderMin: untimedReminderOff),
      );
      expect((await settings.load()).untimedReminderMin, untimedReminderOff);

      await service.create(title: 'Market', day: tomorrow);
      expect(untimed(), isEmpty);
    });

    test('tamamlanınca hatırlatma kalkar', () async {
      final item = await service.create(title: 'Market', day: tomorrow);
      await service.toggleDone(item.id);

      expect(untimed(), isEmpty);
    });
  });
}
