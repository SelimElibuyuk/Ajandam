import 'package:calendar_bridge/calendar_bridge.dart';
import 'package:flutter/services.dart';

/// Telefondaki bir takvim (çoğunlukla Google hesabının takvimleri).
class DeviceCalendarInfo {
  const DeviceCalendarInfo({
    required this.id,
    required this.name,
    required this.account,
    required this.accountType,
    required this.accessLevel,
    this.color,
    this.primary = false,
  });

  final int id;
  final String name;
  final String account;
  final String accountType;
  final int? color;

  /// CalendarContract erişim düzeyi; 500 ve üstü yazılabilir.
  final int accessLevel;
  final bool primary;

  bool get writable => accessLevel >= 500;
  bool get isGoogle => accountType == 'com.google';

  /// Calendars tablosundaki rol adı.
  String get role => accessLevel >= 700
      ? 'owner'
      : writable
      ? 'writer'
      : 'reader';

  factory DeviceCalendarInfo.fromMap(Map<Object?, Object?> m) =>
      DeviceCalendarInfo(
        id: (m['id']! as num).toInt(),
        name: m['name'] as String? ?? '',
        account: m['account'] as String? ?? '',
        accountType: m['accountType'] as String? ?? '',
        color: (m['color'] as num?)?.toInt(),
        accessLevel: (m['accessLevel'] as num?)?.toInt() ?? 0,
        primary: m['primary'] as bool? ?? false,
      );
}

/// Takvim sağlayıcısındaki bir satır: tekli etkinlik, seri ya da serinin
/// değiştirilmiş/iptal edilmiş bir tekrarı ([originalId] dolu).
class RemoteEvent {
  const RemoteEvent({
    required this.key,
    required this.calendarId,
    required this.start,
    required this.end,
    this.title,
    this.description,
    this.allDay = false,
    this.rrule,
    this.exdate,
    this.rdate,
    this.originalId,
    this.originalInstanceTime,
    this.canceled = false,
  });

  /// Satırın kimliği; açılmış tekrarlarda `kimlik@başlangıç`.
  final String key;
  final int calendarId;
  final String? title;
  final String? description;

  /// UTC epoch ms; tüm gün etkinlikte UTC gece yarısı, bitiş hariç.
  final int start;
  final int end;
  final bool allDay;
  final String? rrule;
  final String? exdate;
  final String? rdate;
  final int? originalId;
  final int? originalInstanceTime;
  final bool canceled;

  bool get isException => originalId != null;

  factory RemoteEvent.fromMap(Map<Object?, Object?> m) => RemoteEvent(
    key: '${m['id']}',
    calendarId: (m['calendarId']! as num).toInt(),
    title: m['title'] as String?,
    description: m['description'] as String?,
    start: (m['start']! as num).toInt(),
    end: (m['end']! as num).toInt(),
    allDay: m['allDay'] as bool? ?? false,
    rrule: _blank(m['rrule'] as String?),
    exdate: _blank(m['exdate'] as String?),
    rdate: _blank(m['rdate'] as String?),
    originalId: (m['originalId'] as num?)?.toInt(),
    originalInstanceTime: (m['originalInstanceTime'] as num?)?.toInt(),
    canceled: m['canceled'] as bool? ?? false,
  );

  /// Uygulamanın çözemediği serinin tek bir tekrarı.
  factory RemoteEvent.fromInstance(Map<Object?, Object?> m) => RemoteEvent(
    key: '${m['eventId']}@${m['begin']}',
    calendarId: (m['calendarId']! as num).toInt(),
    title: m['title'] as String?,
    description: m['description'] as String?,
    start: (m['begin']! as num).toInt(),
    end: (m['end']! as num).toInt(),
    allDay: m['allDay'] as bool? ?? false,
    canceled: m['canceled'] as bool? ?? false,
  );

  static String? _blank(String? s) => s == null || s.trim().isEmpty ? null : s;
}

/// Sağlayıcıya yazılacak etkinlik.
class EventWrite {
  const EventWrite({
    required this.title,
    required this.start,
    required this.end,
    required this.allDay,
    this.description,
    this.rrule,
  });

  final String title;
  final String? description;
  final int start;
  final int end;
  final bool allDay;
  final String? rrule;

  Map<String, Object?> toMap() => {
    'title': title,
    'description': description,
    'start': start,
    'end': end,
    'allDay': allDay,
    'rrule': rrule,
  };
}

/// Takvim sağlayıcısı; testlerde sahtesiyle değiştirilir.
abstract class CalendarGateway {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<List<DeviceCalendarInfo>> calendars();
  Future<List<RemoteEvent>> events(List<int> calendarIds, int from, int to);
  Future<List<RemoteEvent>> instances(List<int> eventIds, int from, int to);
  Future<int> insert(int calendarId, EventWrite event);
  Future<bool> update(int id, EventWrite event);
  Future<bool> delete(int id);

  /// Serinin tek tekrarını değiştirir ([event] verilirse) ya da iptal eder.
  Future<int> insertException(
    int parentId,
    int originalInstanceTime, {
    EventWrite? event,
  });
  Future<void> requestSync(List<int> calendarIds);

  /// Takvimde bir şey değişince (uygulama açıkken) haber verir.
  Stream<void> changes();
}

class DeviceCalendar implements CalendarGateway {
  const DeviceCalendar();

  static const _channel = MethodChannel(calendarChannel);
  static const _changes = EventChannel(calendarChangesChannel);

  @override
  Future<bool> hasPermission() async =>
      await _channel.invokeMethod<bool>('hasPermission') ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _channel.invokeMethod<bool>('requestPermission') ?? false;

  Future<String> _timeZone() async =>
      await _channel.invokeMethod<String>('timeZone') ?? 'UTC';

  @override
  Future<List<DeviceCalendarInfo>> calendars() async {
    final rows = await _channel.invokeListMethod<Map>('calendars') ?? [];
    return [for (final r in rows) DeviceCalendarInfo.fromMap(r)];
  }

  @override
  Future<List<RemoteEvent>> events(
    List<int> calendarIds,
    int from,
    int to,
  ) async {
    final rows =
        await _channel.invokeListMethod<Map>('events', {
          'calendarIds': calendarIds,
          'from': from,
          'to': to,
        }) ??
        [];
    return [for (final r in rows) RemoteEvent.fromMap(r)];
  }

  @override
  Future<List<RemoteEvent>> instances(
    List<int> eventIds,
    int from,
    int to,
  ) async {
    if (eventIds.isEmpty) return const [];
    final rows =
        await _channel.invokeListMethod<Map>('instances', {
          'eventIds': eventIds,
          'from': from,
          'to': to,
        }) ??
        [];
    return [for (final r in rows) RemoteEvent.fromInstance(r)];
  }

  @override
  Future<int> insert(int calendarId, EventWrite event) async =>
      (await _channel.invokeMethod<num>('insert', {
        ...event.toMap(),
        'calendarId': calendarId,
        'timeZone': await _timeZone(),
      }))!.toInt();

  @override
  Future<bool> update(int id, EventWrite event) async =>
      await _channel.invokeMethod<bool>('update', {
        ...event.toMap(),
        'id': id,
        'timeZone': await _timeZone(),
      }) ??
      false;

  @override
  Future<bool> delete(int id) async =>
      await _channel.invokeMethod<bool>('delete', {'id': id}) ?? false;

  @override
  Future<int> insertException(
    int parentId,
    int originalInstanceTime, {
    EventWrite? event,
  }) async => (await _channel.invokeMethod<num>('insertException', {
    ...?event?.toMap(),
    'parentId': parentId,
    'originalInstanceTime': originalInstanceTime,
    'canceled': event == null,
    'timeZone': await _timeZone(),
  }))!.toInt();

  @override
  Future<void> requestSync(List<int> calendarIds) =>
      _channel.invokeMethod<bool>('requestSync', {'calendarIds': calendarIds});

  @override
  Stream<void> changes() => _changes.receiveBroadcastStream().map((_) {});
}
