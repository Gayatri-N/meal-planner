import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/views/app_shell_view.dart';
import '../../features/home/bloc/home_bloc.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/recipes/bloc/recipe_detail_bloc.dart';
import '../../features/recipes/bloc/recipes_bloc.dart';
import '../../features/recipes/pages/recipe_detail_page.dart';
import '../../features/recipes/pages/recipes_page.dart';
import '../../features/track/pages/track_page.dart';
import '../../localization/l10n.dart';
import '../di/di.dart';

abstract final class AppRoutes {
  static const home = '/home';
  static const recipes = '/recipes';
  static const track = '/track';
}

/// Dev aid: `--dart-define=INITIAL_ROUTE=/recipes/pithla` opens that screen.
const _initialRoute = String.fromEnvironment(
  'INITIAL_ROUTE',
  defaultValue: AppRoutes.home,
);

/// MVP tabs: Home, Recipes, Track. V1 adds Plan and Shopping branches.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: _initialRoute,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<HomeBloc>()..add(const HomeStarted()),
                  child: const HomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.recipes,
                builder: (context, state) => BlocProvider(
                  create: (_) =>
                      getIt<RecipesBloc>()..add(const RecipesStarted()),
                  child: const RecipesPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<RecipeDetailBloc>()
                        ..add(
                          RecipeDetailStarted(state.pathParameters['id'] ?? ''),
                        ),
                      child: const RecipeDetailPage(),
                    ),
                  ),
                ],
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
