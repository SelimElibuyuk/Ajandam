import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/dates.dart';
import '../domain/item_service.dart';
import '../domain/reminder_planner.dart';
import 'notification_actions.dart';

const _reminderChannel = AndroidNotificationChannel(
  'reminders',
  'Hatırlatmalar',
  description: 'Girdilerin zamanı yaklaşınca gelen bildirimler',
  importance: Importance.high,
);

const _lifecycleChannel = AndroidNotificationChannel(
  'lifecycle',
  'Görev ömrü',
  description: 'Silinmeye yaklaşan görevler',
);

/// Eklenti ana iş parçacığında çalışır. Çağrılar arasında bu kadar soluk
/// verilerek arayüzün kare kaçırması önlenir.
const _breather = Duration(milliseconds: 12);

const _done = AndroidNotificationAction(actionDone, 'Tamamlandı');
const _snooze = AndroidNotificationAction(actionSnooze, '10 dk ertele');
const _tomorrow = AndroidNotificationAction(actionTomorrow, 'Yarına taşı');
const _extend = AndroidNotificationAction(actionExtend, 'Süreyi uzat');

/// Cihazda planlanan yerel bildirimler. İnternete bağlı değildir.
class NotificationService implements ReminderGateway {
  NotificationService._();

  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _ready = Completer<void>();
  late Future<void> _queue = _ready.future;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> init({void Function(NotificationTarget target)? onOpen}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final target = payloadTarget(response.payload);
        if (target != null) onOpen?.call(target);
      },
      onDidReceiveBackgroundNotificationResponse: onNotificationAction,
    );
    await _android?.createNotificationChannel(_reminderChannel);
    await _android?.createNotificationChannel(_lifecycleChannel);
    if (!_ready.isCompleted) _ready.complete();
  }

  /// Uygulama bildirime dokunularak açıldıysa açılacak yeri döndürür.
  Future<NotificationTarget?> launchTarget() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    final response = details!.notificationResponse;
    return response?.actionId == null ? payloadTarget(response?.payload) : null;
  }

  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  /// Planı cihazdaki bildirimlerle eşitler: eskiyenleri kaldırır, eksikleri
  /// ekler. Ekranda duran bildirimlere dokunmaz.
  @override
  Future<void> replaceAll(
    List<PlannedNotification> plans, {
    bool rearm = false,
  }) {
    final run = _queue.then((_) => _sync(plans, rearm: rearm));
    _queue = run.catchError((_) {});
    return run;
  }

  Future<void> _sync(
    List<PlannedNotification> plans, {
    required bool rearm,
  }) async {
    final wanted = {for (final plan in plans) notificationId(plan.key): plan};
    final pending = await _plugin.pendingNotificationRequests();
    final existing = {for (final request in pending) request.id};

    for (final id in existing.difference(wanted.keys.toSet())) {
      await _plugin.cancel(id: id);
      await Future<void>.delayed(_breather);
    }
    for (final entry in wanted.entries) {
      if (!rearm && existing.contains(entry.key)) continue;
      await _schedule(entry.key, entry.value);
      await Future<void>.delayed(_breather);
    }
  }

  Future<void> _schedule(int id, PlannedNotification plan) {
    return _plugin.zonedSchedule(
      id: id,
      // Mutlak an verildiği için saat dilimi veritabanı yüklemeye gerek yok.
      scheduledDate: tz.TZDateTime.from(plan.when, tz.UTC),
      notificationDetails: NotificationDetails(android: _details(plan)),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: plan.title,
      body: plan.body,
      payload: jsonEncode({
        'ids': plan.itemIds,
        if (plan.day != null) 'day': dayKey(plan.day!),
      }),
    );
  }

  AndroidNotificationDetails _details(PlannedNotification plan) {
    final channel = switch (plan.type) {
      NotificationType.item || NotificationType.untimed => _reminderChannel,
      _ => _lifecycleChannel,
    };
    return AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: plan.type == NotificationType.item
          ? Priority.high
          : Priority.defaultPriority,
      styleInformation: plan.lines.isEmpty
          ? BigTextStyleInformation(plan.body)
          : InboxStyleInformation(plan.lines, contentTitle: plan.title),
      actions: switch (plan.type) {
        NotificationType.item => const [_done, _snooze, _tomorrow],
        NotificationType.lifecycle => const [_done, _extend],
        NotificationType.lifecycleGroup => const [_extend],
        NotificationType.untimed =>
          plan.itemIds.length == 1 ? const [_done] : const [],
      },
    );
  }
}

/// Anahtardan üretilen 31 bitlik FNV-1a özeti: aynı plan aynı kimliği alır.
int notificationId(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}
