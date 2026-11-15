import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/settings_repository.dart';
import '../domain/dates.dart';
import '../domain/palettes.dart';
import '../domain/settings.dart';
import '../features/quick_add/quick_add_dialog.dart';
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
  StreamSubscription<Uri?>? _links;
  StreamSubscription<void>? _calendarChanges;
  bool _quickAddOpen = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: _catchUp,
      onPause: () {
        ref.read(itemServiceProvider).flushReplan();
        ref.read(habitServiceProvider).flush();
      },
    );
    ref.listenManual(
      calendarsProvider.select(
        (v) => v.value?.any((c) => c.isVisible) ?? false,
      ),
      (_, connected) => _watchCalendar(connected),
      fireImmediately: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Eşitleme, girdi değişikliklerini dinlemeye buradan başlar.
      ref.read(calendarSyncProvider).schedule(const Duration(seconds: 1));
      _maintain(rearm: true);
      final links = ref.read(widgetLinksProvider);
      links.initial().then((uri) async {
        await _openLink(uri);
        // Widget'tan hızlı ekleme gibi bir bağlantıyla açılınca araya girmez.
        if (uri == null) await _showTipsOnce();
      });
      _links = links.clicks.listen(_openLink);
    });
  }

  /// Uygulama açıkken takvimdeki değişiklik hemen eşitlenir.
  void _watchCalendar(bool connected) {
    _calendarChanges?.cancel();
    _calendarChanges = null;
    if (!connected) return;
    final sync = ref.read(calendarSyncProvider);
    _calendarChanges = ref
        .read(calendarGatewayProvider)
        .changes()
        .listen((_) => sync.schedule(), onError: (_) {});
  }

  @override
  void dispose() {
    _calendarChanges?.cancel();
    _lifecycle.dispose();
    _links?.cancel();
    super.dispose();
  }

  Future<void> _openLink(Uri? uri) async {
    if (uri == null || uri.scheme != 'ajandam') return;
    final router = widget.router ?? appRouter;
    final date = uri.queryParameters['date'] ?? uri.queryParameters['focus'];
    final day = date == null ? null : parseDayKey(date);
    switch (uri.host) {
      case 'quick-add':
        await _openQuickAdd(day, voice: uri.queryParameters['voice'] == '1');
      case 'week':
        // Ayarlar gibi üstte kalan ekranlar kapanmazsa Hafta arkada kalır.
        router.go('/');
        ref
            .read(weekFocusProvider.notifier)
            .show(day ?? ref.read(todayProvider));
      case 'day':
        if (date != null) router.push('/day/$date');
      case 'item':
        if (uri.pathSegments.isNotEmpty) {
          router.push('/item/${uri.pathSegments.first}');
        }
      case 'habit':
        router.go('/');
        ref
            .read(selectedHabitProvider.notifier)
            .select(uri.pathSegments.isEmpty ? null : uri.pathSegments.first);
    }
  }

  Future<void> _showTipsOnce() async {
    final repo = ref.read(settingsRepositoryProvider);
    if (await repo.tipSeen(SettingsRepository.tipsHome)) return;
    ref.read(homeTipsProvider.notifier).request();
  }

  /// Widget'tan eklenince iş bitti demektir, kullanıcı ana ekrana döner.
  Future<void> _openQuickAdd(DateTime? day, {bool voice = false}) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null || _quickAddOpen) return;
    _quickAddOpen = true;
    await showQuickAdd(context, day: day, coldStart: true, voice: voice);
    _quickAddOpen = false;
    await ref.read(itemServiceProvider).flushReplan();
    // Pencere kapanınca süreç durabilir; takvime hemen yazılır.
    await ref
        .read(calendarSyncProvider)
        .sync()
        .timeout(const Duration(seconds: 5), onTimeout: () => null)
        .catchError((_) => null);
    await SystemNavigator.pop();
  }

  void _catchUp() {
    ref.read(itemServiceProvider).applyWidgetActions();
    ref.read(habitServiceProvider).applyWidgetActions();
    ref.read(todayProvider.notifier).refresh();
    ref.read(calendarSyncProvider).schedule(const Duration(milliseconds: 500));
    if (DateTime.now().difference(_lastMaintenance) > _maintenanceGap) {
      _maintain();
    }
  }

  void _maintain({bool rearm = false}) {
    _lastMaintenance = DateTime.now();
    ref.read(itemServiceProvider).runMaintenance(rearm: rearm);
    final habits = ref.read(habitServiceProvider);
    habits.applyWidgetActions().then((_) => habits.publishWidget());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(todayProvider, (_, _) => _maintain());

    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final palette = paletteById(settings.palette);

    return MaterialApp.router(
      title: 'Ajandam',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(
        Brightness.light,
        palette: palette,
        highContrast: settings.highContrast,
      ),
      darkTheme: buildTheme(
        Brightness.dark,
        palette: palette,
        highContrast: settings.highContrast,
      ),
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
