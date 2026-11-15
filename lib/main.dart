import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'notifications/notification_actions.dart';
import 'notifications/notification_service.dart';

/// Eklenti kurulumları ana iş parçacığını kilitler; açılış animasyonu bitince
/// çalışır.
const _startupDelay = Duration(milliseconds: 900);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr');

  runApp(const ProviderScope(child: AjandamApp()));

  // Ekran açıldıktan sonra kurulur, ilk kare beklemez.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(_startupDelay, _startNotifications);
  });
}

Future<void> _startNotifications() async {
  try {
    final notifications = NotificationService.instance;
    await notifications.init(onOpen: _openTarget);
    final launched = await notifications.launchTarget();
    if (launched != null) _openTarget(launched);
    await notifications.requestPermission();
    await registerBackgroundWork();
    await HomeWidget.registerInteractivityCallback(onWidgetAction);
  } catch (error, stack) {
    // Bildirimler çalışmasa da ajanda kullanılabilir kalır.
    debugPrint('Bildirim kurulumu başarısız: $error');
    debugPrintStack(stackTrace: stack);
  }
}

/// Saatsiz görev özeti günü, diğer bildirimler girdiyi açar.
void _openTarget(NotificationTarget target) {
  final day = target.day;
  final id = target.itemId;
  if (day != null) {
    appRouter.push('/day/$day');
  } else if (id != null) {
    appRouter.push('/item/$id');
  }
}
