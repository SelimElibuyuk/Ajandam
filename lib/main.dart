import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'notifications/notification_actions.dart';
import 'notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr');

  runApp(const ProviderScope(child: AjandamApp()));

  // Ekran açıldıktan sonra kurulur, ilk kare beklemez.
  WidgetsBinding.instance.addPostFrameCallback((_) => _startNotifications());
}

Future<void> _startNotifications() async {
  try {
    final notifications = NotificationService.instance;
    await notifications.init(onOpenItem: _openItem);
    final launched = await notifications.launchItem();
    if (launched != null) _openItem(launched);
    await notifications.requestPermission();
    await registerBackgroundWork();
  } catch (error, stack) {
    // Bildirimler çalışmasa da ajanda kullanılabilir kalır.
    debugPrint('Bildirim kurulumu başarısız: $error');
    debugPrintStack(stackTrace: stack);
  }
}

void _openItem(String id) => appRouter.push('/item/$id');
