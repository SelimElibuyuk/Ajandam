import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/settings.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class AjandamApp extends ConsumerStatefulWidget {
  const AjandamApp({super.key, this.router});

  final GoRouter? router;

  @override
  ConsumerState<AjandamApp> createState() => _AjandamAppState();
}

/// Sık uygulama geçişlerinde bakımın boşuna çalışmasını önler. Gün değişimi
/// bundan bağımsız olarak [todayProvider] üzerinden yakalanır.
const _maintenanceGap = Duration(minutes: 10);

class _AjandamAppState extends ConsumerState<AjandamApp> {
  late final AppLifecycleListener _lifecycle;
  DateTime _lastMaintenance = DateTime.now();

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: _catchUp,
      onPause: () => ref.read(itemServiceProvider).flushReplan(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maintain(rearm: true));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _catchUp() {
    ref.read(todayProvider.notifier).refresh();
    if (DateTime.now().difference(_lastMaintenance) > _maintenanceGap) {
      _maintain();
    }
  }

  void _maintain({bool rearm = false}) {
    _lastMaintenance = DateTime.now();
    ref.read(itemServiceProvider).runMaintenance(rearm: rearm);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(todayProvider, (_, _) => _maintain());
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();

    return MaterialApp.router(
      title: 'Ajandam',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (settings.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: widget.router ?? appRouter,
    );
  }
}
