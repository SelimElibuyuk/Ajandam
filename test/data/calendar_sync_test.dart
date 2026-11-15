import 'package:ajandam/data/db/app_database.dart';
import 'package:ajandam/data/repositories/item_repository.dart';
import 'package:ajandam/data/repositories/settings_repository.dart';
import 'package:ajandam/data/sync/calendar_mapping.dart';
import 'package:ajandam/data/sync/calendar_sync.dart';
import 'package:ajandam/data/sync/device_calendar.dart';
import 'package:ajandam/domain/dates.dart';
import 'package:ajandam/domain/item.dart';
import 'package:ajandam/domain/item_service.dart';
import 'package:ajandam/domain/recurrence.dart';
import 'package:ajandam/domain/reminder_planner.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Telefonun takvim sağlayıcısının bellekteki taklidi.
class FakeCalendar implements CalendarGateway {
  final calendars0 = [
    const DeviceCalendarInfo(
      id: 1,
      name: 'Kişisel',
      account: 'ben@example.com',
      accountType: 'com.google',
      accessLevel: 700,
      primary: true,
    ),
    const DeviceCalendarInfo(
      id: 2,
      name: 'Tatiller',
      account: 'ben@example.com',
      accountType: 'com.google',
      accessLevel: 200,
    ),
  ];
  final stored = <int, RemoteEvent>{};
  final syncRequests = <List<int>>[];
  int _next = 100;
  bool permission = true;

  int add({
    required String title,
    required int start,
    required int end,
    int calendarId = 1,
    bool allDay = false,
    String? description,
    String? rrule,
    String? exdate,
  }) {
    final id = _next++;
    stored[id] = RemoteEvent(
      key: '$id',
      calendarId: calendarId,
      title: title,
      description: description,
      start: start,
      end: end,
      allDay: allDay,
      rrule: rrule,
      exdate: exdate,
    );
    return id;
  }

  RemoteEvent byTitle(String title) =>
      stored.values.firstWhere((e) => e.title == title);

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<List<DeviceCalendarInfo>> calendars() async => calendars0;

  @override
  Future<List<RemoteEvent>> events(
    List<int> calendarIds,
    int from,
    int to,
  ) async => [
    for (final e in stored.values)
      if (calendarIds.contains(e.calendarId) &&
          e.start < to &&
          (e.rrule != null || e.end >= from || e.isException))
        e,
  ];

  /// Çözülemeyen seride iki tekrar: ilk gün ve bir hafta sonrası.
  @override
  Future<List<RemoteEvent>> instances(
    List<int> eventIds,
    int from,
    int to,
  ) async => [
    for (final id in eventIds)
      for (final week in [0, 1])
        RemoteEvent(
          key: '$id@${stored[id]!.start + week * 7 * 86400000}',
          calendarId: stored[id]!.calendarId,
          title: stored[id]!.title,
          start: stored[id]!.start + week * 7 * 86400000,
          end: stored[id]!.end + week * 7 * 86400000,
        ),
  ];

  RemoteEvent _from(String key, int calendarId, EventWrite w) => RemoteEvent(
    key: key,
    calendarId: calendarId,
    title: w.title,
    description: w.description,
    start: w.start,
    end: w.end,
    allDay: w.allDay,
    rrule: w.rrule,
  );

  @override
  Future<int> insert(int calendarId, EventWrite event) async {
    final id = _next++;
    stored[id] = _from('$id', calendarId, event);
    return id;
  }

  @override
  Future<bool> update(int id, EventWrite event) async {
    final old = stored[id];
    if (old == null) return false;
    stored[id] = RemoteEvent(
      key: old.key,
      calendarId: old.calendarId,
      title: event.title,
      description: event.description,
      start: event.start,
      end: event.end,
      allDay: event.allDay,
      rrule: event.rrule,
      originalId: old.originalId,
      originalInstanceTime: old.originalInstanceTime,
    );
    return true;
  }

  @override
  Future<bool> delete(int id) async {
    stored.removeWhere((k, e) => k == id || e.originalId == id);
    return true;
  }

  @override
  Future<int> insertException(
    int parentId,
    int originalInstanceTime, {
    EventWrite? event,
  }) async {
    final id = _next++;
    final parent = stored[parentId]!;
    stored[id] = RemoteEvent(
      key: '$id',
      calendarId: parent.calendarId,
      title: event?.title ?? parent.title,
      description: event?.description,
      start: event?.start ?? originalInstanceTime,
      end: event?.end ?? originalInstanceTime,
      allDay: event?.allDay ?? parent.allDay,
      originalId: parentId,
      originalInstanceTime: originalInstanceTime,
      canceled: event == null,
    );
    return id;
  }

  @override
  Future<void> requestSync(List<int> calendarIds) async =>
      syncRequests.add(calendarIds);

  @override
  Stream<void> changes() => const Stream.empty();
}

String utcStamp(DateTime local) {
  final u = local.toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${u.year}${two(u.month)}${two(u.day)}T'
      '${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
}

class _NoReminders implements ReminderGateway {
  @override
  Future<void> replaceAll(
    List<PlannedNotification> plans, {
    bool rearm = false,
  }) async {}
}

void main() {
  late AppDatabase db;
  late FakeCalendar calendar;
  late ItemService items;
  late ItemRepository repo;
  late CalendarSync sync;
  late DateTime now;
  var ids = 0;

  final today = DateTime(2026, 11, 12);
  int at(DateTime day, int hour, [int minute = 0]) => DateTime(
    day.year,
    day.month,
    day.day,
    hour,
    minute,
  ).millisecondsSinceEpoch;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    calendar = FakeCalendar();
    repo = ItemRepository(db);
    now = DateTime(2026, 11, 12, 10);
    items = ItemService(
      store: repo,
      settings: SettingsRepository(db),
      reminders: _NoReminders(),
      newId: () => 'id${ids++}',
      clock: () => now,
    );
    sync = CalendarSync(
      db: db,
      gateway: calendar,
      newId: () => 'g${ids++}',
      clock: () => now,
    );
  });
  tearDown(() => db.close());

  Future<void> connect() => sync.configure(
    shown: calendar.calendars0,
    target: calendar.calendars0.first,
  );

  /// Her değişiklik sonraki eşitlemede ayrı görünsün diye saat ilerler.
  Future<SyncResult?> run() async {
    now = now.add(const Duration(minutes: 1));
    final result = await sync.sync();
    now = now.add(const Duration(minutes: 1));
    return result;
  }

  Future<List<AgendaItem>> on(DateTime day) => repo.itemsAround(day, day);

  Future<Item> row(String id) =>
      (db.select(db.items)..where((t) => t.id.equals(id))).getSingle();

  test('bağlanınca güncel girdiler yazılır, geçmiştekiler yazılmaz', () async {
    await items.create(
      title: 'dişçi',
      day: addDays(today, 1),
      start: DateTime(2026, 11, 13, 15, 30),
    );
    await items.create(title: 'fatura öde', day: addDays(today, 2));
    await items.create(
      title: 'eski etkinlik',
      day: addDays(today, -5),
      kind: ItemKind.event,
    );
    await items.create(title: 'kalan görev', day: addDays(today, -3));
    await connect();
    await run();

    final dentist = calendar.byTitle('dişçi');
    expect(dentist.start, at(addDays(today, 1), 15, 30));
    expect(dentist.end - dentist.start, taskMinutes * 60000);
    expect(dentist.description, taskMarker);
    final bill = calendar.byTitle('fatura öde');
    expect(bill.allDay, isTrue);
    expect(bill.start, utcMidnight(addDays(today, 2)));
    expect(
      calendar.stored.values.any((e) => e.title == 'eski etkinlik'),
      isFalse,
    );
    expect(calendar.stored.values.any((e) => e.title == 'kalan görev'), isTrue);
    expect(calendar.syncRequests, isNotEmpty);

    // İkinci eşitleme bir şey yazmaz.
    final count = calendar.stored.length;
    final again = await run();
    expect(again!.pushed, 0);
    expect(calendar.stored.length, count);
  });

  test('takvimde eklenen etkinlik uygulamaya gelir', () async {
    await connect();
    calendar.add(
      title: 'Toplantı',
      start: at(today, 14),
      end: at(today, 16),
      description: 'Oda 3',
    );
    calendar.add(
      title: 'Tatil',
      start: utcMidnight(addDays(today, 3)),
      end: utcMidnight(addDays(today, 6)),
      allDay: true,
    );
    await run();

    final meeting = (await on(today)).single;
    expect(meeting.title, 'Toplantı');
    expect(meeting.isTask, isFalse);
    expect(meeting.notes, 'Oda 3');
    expect(meeting.end, DateTime(2026, 11, 12, 16));
    final holiday = await row((await on(addDays(today, 4))).single.id);
    expect(holiday.date, dayKey(addDays(today, 3)));
    expect(holiday.endDate, dayKey(addDays(today, 5)));
    expect((await row(meeting.id)).source, 'google');
  });

  test('iki yönlü değişiklik: takvimdeki gelir, uygulamadaki gider', () async {
    await connect();
    final id = calendar.add(
      title: 'Koşu',
      start: at(today, 18),
      end: at(today, 19),
    );
    await run();
    final item = (await on(today)).single;

    calendar.stored[id] = RemoteEvent(
      key: '$id',
      calendarId: 1,
      title: 'Koşu parkta',
      start: at(today, 19),
      end: at(today, 20),
    );
    await run();
    final moved = (await on(today)).single;
    expect(moved.title, 'Koşu parkta');
    expect(moved.start, DateTime(2026, 11, 12, 19));

    await items.save(moved.copyWith(title: 'Koşu sahilde'));
    await run();
    expect(calendar.stored[id]!.title, 'Koşu sahilde');
    expect((await on(today)).single.id, item.id);
  });

  test('tamamlanan görev takvimde ✓ ile görünür', () async {
    await connect();
    final task = await items.create(title: 'ilaç al', day: today);
    await run();
    await items.toggleDone(task.id);
    await run();
    expect(calendar.stored.values.single.title, '${donePrefix}ilaç al');
    // Geri dönüşte tamamlanma korunur.
    await run();
    expect((await on(today)).single.isDone, isTrue);
  });

  test(
    'takvimde silinen: Google girdisi kalkar, uygulamanınki çöpe gider',
    () async {
      await connect();
      final remoteId = calendar.add(
        title: 'Doğum günü',
        start: at(today, 20),
        end: at(today, 22),
      );
      final mine = await items.create(title: 'kitap oku', day: today);
      await run();
      calendar.stored.remove(remoteId);
      calendar.stored.remove(int.parse((await row(mine.id)).googleEventId!));
      await run();

      expect(await on(today), isEmpty);
      final trash = await repo.watchTrash().first;
      expect(trash.map((i) => i.title), ['kitap oku']);
    },
  );

  test('uygulamada silinen takvimden de silinir, kalıcı silme dahil', () async {
    await connect();
    final a = await items.create(title: 'a', day: today);
    final b = await items.create(title: 'b', day: today);
    await run();
    expect(calendar.stored, hasLength(2));

    await items.delete(a.id);
    await run();
    expect(calendar.stored.values.map((e) => e.title), ['b']);

    // Eşitlenmeden kalıcı silinse de takvimdeki gider.
    await items.delete(b.id);
    await items.deleteForever(b.id);
    await run();
    expect(calendar.stored, isEmpty);
  });

  test('tekrarlayan görev seri olur, tamamlanan tekrar istisna olur', () async {
    await connect();
    final series = await items.create(
      title: 'spor',
      day: today,
      start: DateTime(2026, 11, 12, 19),
      recurrence: const Recurrence(
        Frequency.weekly,
        weekdays: {DateTime.monday},
      ),
    );
    await run();
    final master = calendar.byTitle('spor');
    expect(master.rrule, 'FREQ=WEEKLY;BYDAY=MO');
    final monday = DateTime(2026, 11, 16);
    expect(master.start, at(monday, 19));

    await items.toggleDone(occurrenceId(series.id, monday));
    await run();
    final exception = calendar.stored.values.singleWhere((e) => e.isException);
    expect(exception.title, '${donePrefix}spor');
    expect(exception.originalInstanceTime, at(monday, 19));

    // Geri okununca değişmez, yeniden yazılmaz.
    final result = await run();
    expect(result!.pushed, 0);
    expect((await on(monday)).single.isDone, isTrue);
  });

  test('takvimdeki iptal ve EXDATE tekrarları uygulamada görünmez', () async {
    await connect();
    final first = DateTime(2026, 11, 13);
    final id = calendar.add(
      title: 'Ders',
      start: at(first, 9),
      end: at(first, 10),
      rrule: 'FREQ=DAILY;COUNT=5',
      exdate: utcStamp(DateTime(2026, 11, 15, 9)),
    );
    await run();
    expect((await on(addDays(first, 4))).single.title, 'Ders');
    expect(await on(addDays(first, 5)), isEmpty, reason: 'COUNT=5');
    expect(await on(addDays(first, 2)), isEmpty, reason: 'EXDATE');

    await calendar.insertException(id, at(addDays(first, 1), 9));
    await run();
    expect(await on(addDays(first, 1)), isEmpty);
    expect((await on(first)).single.title, 'Ders');
  });

  test('uygulamada silinen tekrar takvimde iptal olur', () async {
    await connect();
    final series = await items.create(
      title: 'yoga',
      day: today,
      start: DateTime(2026, 11, 12, 8),
      durationMin: 60,
      recurrence: const Recurrence(Frequency.daily),
    );
    await run();
    final tomorrow = addDays(today, 1);
    await items.delete(occurrenceId(series.id, tomorrow));
    await run();
    final canceled = calendar.stored.values.singleWhere((e) => e.isException);
    expect(canceled.canceled, isTrue);
    expect(canceled.originalInstanceTime, at(tomorrow, 8));
    await run();
    expect(await on(tomorrow), isEmpty);
    expect((await on(addDays(today, 2))).single.title, 'yoga');
  });

  test('takvimde değişen tekrar uygulamada o güne işlenir', () async {
    await connect();
    final id = calendar.add(
      title: 'Ders',
      start: at(today, 9),
      end: at(today, 10),
      rrule: 'FREQ=WEEKLY',
    );
    await run();
    final next = addDays(today, 7);
    await calendar.insertException(
      id,
      at(next, 9),
      event: EventWrite(
        title: 'Ders (telafi)',
        start: at(next, 13),
        end: at(next, 14),
        allDay: false,
      ),
    );
    await run();
    final moved = (await on(next)).single;
    expect(moved.title, 'Ders (telafi)');
    expect(moved.start, DateTime(2026, 11, 19, 13));
    expect((await on(addDays(today, 14))).single.title, 'Ders');
    final result = await run();
    expect(result!.pushed, 0);
  });

  test('gece taşınan görevin takvimdeki günü de değişir', () async {
    await connect();
    final task = await items.create(title: 'rapor', day: today);
    await run();
    now = DateTime(2026, 11, 13, 0, 5);
    await items.runMaintenance();
    await run();
    final e = calendar.stored[int.parse((await row(task.id)).googleEventId!)]!;
    expect(e.start, utcMidnight(DateTime(2026, 11, 13)));
  });

  test('çözülemeyen kural tek tek ve salt okunur gelir', () async {
    await connect();
    calendar.add(
      title: 'Kulüp',
      start: at(today, 18),
      end: at(today, 19),
      rrule: 'FREQ=MONTHLY;BYDAY=2TH',
    );
    await run();
    final items0 = await on(today);
    expect(items0.single.readOnly, isTrue);
    expect((await on(addDays(today, 7))).single.title, 'Kulüp');
  });

  test('salt okunur takvimdeki değişiklik takvime gitmez', () async {
    await connect();
    final id = calendar.add(
      title: 'Bayram',
      calendarId: 2,
      start: utcMidnight(today),
      end: utcMidnight(addDays(today, 1)),
      allDay: true,
    );
    await run();
    final holiday = (await on(today)).single;
    expect(holiday.readOnly, isTrue);
    await items.save(holiday.copyWith(title: 'Bayram tatili'));
    await run();
    expect(calendar.stored[id]!.title, 'Bayram');
  });

  test(
    'aynı ad ve saatteki takvim satırıyla eşleşir, çift kayıt olmaz',
    () async {
      calendar.add(title: 'Dişçi', start: at(today, 15), end: at(today, 16));
      await items.create(
        title: 'dişçi',
        day: today,
        start: DateTime(2026, 11, 12, 15),
        durationMin: 60,
      );
      await connect();
      await run();
      expect(calendar.stored, hasLength(1));
      expect(await on(today), hasLength(1));
    },
  );

  test(
    'bağlantı kesilince Google girdileri kalkar, uygulamanınkiler kalır',
    () async {
      await connect();
      calendar.add(title: 'Uzaktan', start: at(today, 9), end: at(today, 10));
      await items.create(title: 'yerel', day: today);
      await run();
      expect(await on(today), hasLength(2));

      await sync.disconnect();
      final left = await on(today);
      expect(left.map((i) => i.title), ['yerel']);
      expect((await row(left.single.id)).googleEventId, isNull);
      expect(await sync.isConnected(), isFalse);
      // Bağlı değilken eşitleme bir şey yapmaz.
      expect(await run(), isNull);
    },
  );

  test('takvim izni yoksa dokunulmaz', () async {
    await connect();
    await items.create(title: 'yerel', day: today);
    calendar.permission = false;
    final result = await run();
    expect(result!.permission, isFalse);
    expect(calendar.stored, isEmpty);
  });

  group('eşleme', () {
    test('desteklenen kurallar', () {
      final first = DateTime(2026, 11, 2);
      expect(
        supportedRule('FREQ=WEEKLY;BYDAY=MO,WE;WKST=MO', first)!.toRrule(),
        'FREQ=WEEKLY;BYDAY=MO,WE',
      );
      expect(
        supportedRule('FREQ=DAILY;COUNT=3', first)!.until,
        DateTime(2026, 11, 4),
      );
      expect(supportedRule('FREQ=MONTHLY;BYDAY=1MO', first), isNull);
      expect(supportedRule('FREQ=MONTHLY;BYMONTHDAY=2', first), isNotNull);
      expect(supportedRule('FREQ=MONTHLY;BYMONTHDAY=5', first), isNull);
      expect(supportedRule('FREQ=HOURLY', first), isNull);
    });

    test('saatli seride UNTIL günün sonunun UTC zamanıdır', () {
      final rule = Recurrence(Frequency.daily, until: DateTime(2026, 12, 31));
      final text = googleRrule(rule, timed: true);
      expect(text, startsWith('FREQ=DAILY;UNTIL='));
      expect(
        supportedRule(text, DateTime(2026, 12, 1))!.until,
        DateTime(2026, 12, 31),
      );
      expect(googleRrule(rule, timed: false), 'FREQ=DAILY;UNTIL=20261231');
    });

    test('görev işareti ve tamamlanma ayrıştırılır', () {
      final f = fieldsFromRemote(
        RemoteEvent(
          key: '1',
          calendarId: 1,
          title: '✓ su iç',
          description: 'not\n\n$taskMarker',
          start: utcMidnight(DateTime(2026, 11, 12)),
          end: utcMidnight(DateTime(2026, 11, 13)),
          allDay: true,
        ),
      );
      expect(f.isTask, isTrue);
      expect(f.done, isTrue);
      expect(f.title, 'su iç');
      expect(f.notes, 'not');
      expect(f.allDay, isFalse);
      expect(f.date, '2026-11-12');
    });
  });
}
