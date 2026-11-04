import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

import '../data/db/app_database.dart';
import '../data/repositories/habit_repository.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/habit_service.dart';
import '../domain/item_service.dart';
import '../widget_bridge/home_widget_bridge.dart';
import 'notification_service.dart';

const actionDone = 'done';
const actionSnooze = 'snooze';
const actionTomorrow = 'tomorrow';
const actionExtend = 'extend';

const _maintenanceTask = 'ajandam.maintenance';

List<String> payloadItemIds(String? payload) {
  if (payload == null) return const [];
  final data = jsonDecode(payload) as Map<String, dynamic>;
  return (data['ids'] as List).cast<String>();
}

ItemService buildItemService(AppDatabase db) => ItemService(
  store: ItemRepository(db),
  settings: SettingsRepository(db),
  reminders: NotificationService.instance,
  newId: const Uuid().v7,
  widget: const HomeWidgetBridge(),
);

HabitService buildHabitService(AppDatabase db) => HabitService(
  store: HabitRepository(db),
  settings: SettingsRepository(db),
  newId: const Uuid().v7,
  widget: const HomeWidgetBridge(),
);

Future<void> _withService(
  Future<void> Function(ItemService) work, {
  Future<void> Function(HabitService)? habits,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  final db = AppDatabase();
  try {
    await work(buildItemService(db));
    if (habits != null) await habits(buildHabitService(db));
  } finally {
    await db.close();
  }
}

/// Bildirim düğmeleri uygulama kapalıyken de ayrı bir isolate'te çalışır.
@pragma('vm:entry-point')
Future<void> onNotificationAction(NotificationResponse response) async {
  final ids = payloadItemIds(response.payload);
  if (ids.isEmpty) return;
  await _withService((service) async {
    switch (response.actionId) {
      case actionDone:
        await service.complete(ids.first);
      case actionSnooze:
        await service.snooze(ids.first);
      case actionTomorrow:
        await service.moveToTomorrow(ids.first);
      case actionExtend:
        await service.extend(ids);
    }
  });
}

/// Widget'taki kutu uygulama kapalıyken de kalıcı olarak işlenir.
@pragma('vm:entry-point')
Future<void> onWidgetAction(Uri? uri) => _withService(
  (service) => service.applyWidgetActions(),
  habits: (habits) => habits.applyWidgetActions(),
);

@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await _withService(
      (service) => service.runMaintenance(),
      habits: (habits) async {
        // Gün değişince widget'ın taşıdığı pencere ve seri tazelenir.
        await habits.applyWidgetActions();
        await habits.publishWidget();
      },
    );
    return true;
  });
}

/// Uygulama açılmasa da taşıma ve silme kuralları saatte bir işlenir.
Future<void> registerBackgroundWork() async {
  await Workmanager().initialize(backgroundDispatcher);
  await Workmanager().registerPeriodicTask(
    _maintenanceTask,
    _maintenanceTask,
    frequency: const Duration(hours: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
