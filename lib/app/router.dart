import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../domain/dates.dart';
import '../features/day/day_screen.dart';
import '../features/home/home_screen.dart';
import '../features/item/item_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/trash_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = buildRouter();

GoRouter buildRouter() => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/day/:date',
      builder: (context, state) =>
          DayScreen(day: parseDayKey(state.pathParameters['date']!)),
    ),
    GoRoute(
      path: '/item/:id',
      builder: (context, state) => ItemScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(path: '/trash', builder: (context, state) => const TrashScreen()),
  ],
);
