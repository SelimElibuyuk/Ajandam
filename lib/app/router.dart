import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/dates.dart';
import '../features/item/item_screen.dart';
import '../features/quick_add/quick_add_sheet.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/trash_screen.dart';
import '../features/today/day_screen.dart';
import '../features/today/today_screen.dart';
import '../features/week/week_screen.dart';

final appRouter = buildRouter();

GoRouter buildRouter() => GoRouter(
  initialLocation: '/today',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _Shell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
              builder: (context, state) => const TodayScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/week',
              builder: (context, state) => const WeekScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/day/:date',
      builder: (context, state) =>
          DayScreen(day: parseDayKey(state.pathParameters['date']!)),
    ),
    GoRoute(
      path: '/item/:id',
      builder: (context, state) => ItemScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/trash', builder: (context, state) => const TrashScreen()),
  ],
);

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Metin alanları sheet içinde; klavye açılırken liste yeniden hesaplanmaz.
      resizeToAvoidBottomInset: false,
      body: SafeArea(child: shell),
      floatingActionButton: shell.currentIndex == 0
          ? FloatingActionButton(
              tooltip: 'Ekle',
              onPressed: () => showQuickAdd(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Bugün',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_agenda_outlined),
            selectedIcon: Icon(Icons.view_agenda),
            label: 'Hafta',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
