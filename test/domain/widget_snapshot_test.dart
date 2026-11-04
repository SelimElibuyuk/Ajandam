import 'dart:convert';

import 'package:ajandam/data/db/app_database.dart';
import 'package:ajandam/data/repositories/item_repository.dart';
import 'package:ajandam/data/repositories/settings_repository.dart';
import 'package:ajandam/domain/item.dart';
import 'package:ajandam/domain/item_service.dart';
import 'package:ajandam/domain/palettes.dart';
import 'package:ajandam/domain/reminder_planner.dart';
import 'package:ajandam/domain/settings.dart';
import 'package:ajandam/domain/widget_snapshot.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoReminders implements ReminderGateway {
  List<PlannedNotification> plans = [];

  @override
  Future<void> replaceAll(
    List<PlannedNotification> next, {
    bool rearm = false,
  }) async => plans = next;
}

class _FakeWidget implements WidgetGateway {
  Map<String, dynamic>? snapshot;
  List<DateTime> refreshTimes = [];
  List<WidgetAction> pending = [];

  @override
  Future<void> publish(String json, List<DateTime> times) async {
    snapshot = jsonDecode(json) as Map<String, dynamic>;
    refreshTimes = times;
  }

  @override
  Future<List<WidgetAction>> takeActions() async {
    final out = pending;
    pending = [];
    return out;
  }
}

AgendaItem _item(
  String id, {
  required DateTime day,
  DateTime? start,
  DateTime? end,
  ItemKind kind = ItemKind.task,
  DateTime? doneAt,
}) => AgendaItem(
  id: id,
  kind: kind,
  title: 'Girdi $id',
  day: day,
  start: start,
  end: end,
  doneAt: doneAt,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  final today = DateTime(2026, 11, 3);
  final now = DateTime(2026, 11, 3, 10);

  Map<String, dynamic> snapshot(List<AgendaItem> items) => buildSnapshot(
    items,
    today: today,
    now: now,
    settings: const AppSettings(),
  );

  List<dynamic> dayItems(Map<String, dynamic> s, String date) =>
      ((s['days'] as List).firstWhere((d) => d['date'] == date) as Map)['items']
          as List;

  group('buildSnapshot', () {
    test('dün ve sonraki 7 günü içerir', () {
      final days = snapshot(const [])['days'] as List;

      expect(days.first['date'], '2026-11-02');
      expect(days.last['date'], '2026-11-10');
      expect(days, hasLength(9));
    });

    test('sıra saatli sonra saatsiz, kalan sayısı doğru', () {
      final s = snapshot([
        _item('saatsiz', day: today),
        _item('saatli', day: today, start: DateTime(2026, 11, 3, 14)),
        _item('bitti', day: today, doneAt: now),
      ]);

      final items = dayItems(s, '2026-11-03');
      expect(items.map((i) => i['id']), ['saatli', 'saatsiz', 'bitti']);
      expect(items.first['time'], '14:00');
      expect((s['days'] as List)[1]['remaining'], 2);
    });

    test('bitenler saatli olsa da en alta iner', () {
      final s = snapshot([
        _item(
          'biten etkinlik',
          day: today,
          kind: ItemKind.event,
          start: DateTime(2026, 11, 3, 8),
          end: DateTime(2026, 11, 3, 9),
        ),
        _item(
          'biten görev',
          day: today,
          start: DateTime(2026, 11, 3, 7),
          doneAt: now,
        ),
        _item('saatsiz', day: today),
        _item('öğlen', day: today, start: DateTime(2026, 11, 3, 12)),
        _item('akşam', day: today, start: DateTime(2026, 11, 3, 19)),
      ]);

      expect(dayItems(s, '2026-11-03').map((i) => i['id']), [
        'öğlen',
        'akşam',
        'saatsiz',
        'biten görev',
        'biten etkinlik',
      ]);
    });

    test('eski tamamlanmamış görev bugüne gelir, gerçek günü korunur', () {
      final s = snapshot([_item('eski', day: DateTime(2026, 10, 20))]);

      final items = dayItems(s, '2026-11-03');
      expect(items.single['id'], 'eski');
      expect(items.single['day'], '2026-10-20');
    });

    test('ayar değerleri widget\'a taşınır', () {
      final s = buildSnapshot(
        const [],
        today: today,
        now: now,
        settings: const AppSettings(widgetTapMode: 'week_view', theme: 'light'),
      );

      expect(s['tapMode'], 'week_view');
      expect(s['theme'], 'light');
    });

    test('tema renkleri ve widget görünümü widget\'a taşınır', () {
      final s = buildSnapshot(
        const [],
        today: today,
        now: now,
        settings: const AppSettings(widgetOpacity: 80, widgetRadius: 8),
      );

      expect(s['palette'], 'nocturne');
      final colors = s['colors'] as Map<String, dynamic>;
      expect((colors['dark'] as Map)['surface'], '#FF121316');
      expect((colors['light'] as Map)['accent'], '#FF4A6FA5');
      expect(s['widgetStyle'], {'opacity': 80, 'radius': 8});
    });

    test(
      'tema ve widget ayarları kaydedilir, bilinmeyen tema Nocturne olur',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = SettingsRepository(db);
        await repo.save(
          const AppSettings(
            palette: 'orman',
            widgetOpacity: 60,
            widgetRadius: 24,
          ),
        );
        final loaded = await repo.load();
        expect(loaded.palette, 'orman');
        expect(loaded.widgetOpacity, 60);
        expect(loaded.widgetRadius, 24);
        expect(paletteById(loaded.palette).id, 'nocturne');
      },
    );

    test('uzun başlık kısaltılır, boyut sınırı aşılmaz', () {
      final items = [
        for (var d = 0; d < 8; d++)
          for (var i = 0; i < 40; i++)
            _item(
              '$d-$i',
              day: DateTime(2026, 11, 3 + d),
            ).copyWith(title: 'x' * 300),
      ];

      final json = jsonEncode(snapshot(items));

      expect(json.length, lessThan(50 * 1024));
    });
  });

  group('widgetRefreshTimes', () {
    test('gece yarısını ve bugünkü saatleri içerir', () {
      final times = widgetRefreshTimes([
        _item('g', day: today, start: DateTime(2026, 11, 3, 14)),
        _item(
          'e',
          day: today,
          kind: ItemKind.event,
          start: DateTime(2026, 11, 3, 15),
          end: DateTime(2026, 11, 3, 16),
        ),
      ], now);

      expect(times.last, DateTime(2026, 11, 4));
      expect(times.first, DateTime(2026, 11, 3, 14, 0, 30));
      expect(times[1], DateTime(2026, 11, 3, 16, 0, 30));
    });

    test('geçmiş ve uzak saatleri atlar, sınırı aşmaz', () {
      final past = widgetRefreshTimes([
        _item('g', day: today, start: DateTime(2026, 11, 3, 9)),
        _item('u', day: today, start: DateTime(2026, 11, 8, 9)),
      ], now);
      expect(past, [DateTime(2026, 11, 4)]);

      final many = widgetRefreshTimes([
        for (var i = 0; i < 40; i++)
          _item('$i', day: today, start: DateTime(2026, 11, 3, 10, 5 + i)),
      ], now);
      expect(many, hasLength(24));
    });
  });

  group('ItemService ile', () {
    late AppDatabase db;
    late ItemRepository repo;
    late _FakeWidget widget;
    late _NoReminders reminders;
    late ItemService service;
    var clock = now;
    var nextId = 0;

    setUp(() {
      clock = now;
      db = AppDatabase(NativeDatabase.memory());
      repo = ItemRepository(db);
      widget = _FakeWidget();
      reminders = _NoReminders();
      service = ItemService(
        store: repo,
        settings: SettingsRepository(db),
        reminders: reminders,
        newId: () => 'w${nextId++}',
        widget: widget,
        clock: () => clock,
      );
    });
    tearDown(() => db.close());

    test('girdi eklenince widget güncellenir', () async {
      await service.create(title: 'Market', day: today);

      expect(
        dayItems(widget.snapshot!, '2026-11-03').single['title'],
        'Market',
      );
    });

    test('widget dokunuşu kayda işlenir ve hatırlatmayı kaldırır', () async {
      final item = await service.create(
        title: 'Dişçi',
        day: today,
        start: DateTime(2026, 11, 3, 14),
        reminderMin: 15,
      );
      expect(
        reminders.plans.where((p) => p.type == NotificationType.item),
        hasLength(1),
      );

      widget.pending = [WidgetAction(id: item.id, done: true, at: now)];
      await service.applyWidgetActions();

      expect((await repo.byId(item.id))!.doneAt, now);
      expect(
        reminders.plans.where((p) => p.type == NotificationType.item),
        isEmpty,
      );
      expect(dayItems(widget.snapshot!, '2026-11-03').single['done'], isTrue);
    });

    test('widget\'ta geri alma tamamlanmayı kaldırır', () async {
      final item = await service.create(title: 'Market', day: today);
      await service.complete(item.id);

      widget.pending = [WidgetAction(id: item.id, done: false, at: now)];
      await service.applyWidgetActions();

      expect((await repo.byId(item.id))!.isDone, isFalse);
    });

    test('silinmiş girdiye gelen dokunuş sorun çıkarmaz', () async {
      widget.pending = [WidgetAction(id: 'yok', done: true, at: now)];

      await service.applyWidgetActions();

      expect(widget.pending, isEmpty);
    });

    test('bakım bekleyen dokunuşları da işler', () async {
      final item = await service.create(title: 'Market', day: today);
      widget.pending = [WidgetAction(id: item.id, done: true, at: now)];

      await service.runMaintenance();

      expect((await repo.byId(item.id))!.isDone, isTrue);
    });

    test('gece taşınan görev widget\'ta yeni günde görünür', () async {
      await service.create(title: 'Rapor', day: today);
      clock = DateTime(2026, 11, 4, 0, 5);

      await service.runMaintenance();

      expect(dayItems(widget.snapshot!, '2026-11-04').single['title'], 'Rapor');
      expect(dayItems(widget.snapshot!, '2026-11-03'), isEmpty);
    });
  });
}
