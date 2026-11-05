import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/views/app_shell_view.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/recipes/pages/recipes_page.dart';
import '../../features/track/pages/track_page.dart';
import '../../localization/l10n.dart';

abstract final class AppRoutes {
  static const home = '/home';
  static const recipes = '/recipes';
  static const track = '/track';
}

/// MVP tabs: Home, Recipes, Track. V1 adds Plan and Shopping branches.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.recipes,
                builder: (context, state) => const RecipesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.track,
                builder: (context, state) => const TrackPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppShellView(
      currentIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        // Tapping the current tab again returns to its first page.
        initialLocation: index == navigationShell.currentIndex,
      ),
      destinations: [
        AppShellDestination(
          label: l10n.navHome,
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
        ),
        AppShellDestination(
          label: l10n.navRecipes,
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book,
        ),
        AppShellDestination(
          label: l10n.navTrack,
          icon: Icons.event_note_outlined,
          selectedIcon: Icons.event_note,
        ),
      ],
      child: navigationShell,
    );
  }
}
