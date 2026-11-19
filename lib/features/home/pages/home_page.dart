import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../design_system/views/today_view.dart';
import '../../../domain/models/day.dart';
import '../../../domain/models/meal.dart';
import '../../../domain/models/meal_item.dart';
import '../../../domain/models/meal_status.dart';
import '../../../domain/models/meal_type.dart';
import '../../../localization/l10n.dart';
import '../../recipes/pages/recipe_formatting.dart';
import '../bloc/home_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _OnResume(
      // Back from the background: it may be a new day by now.
      onResume: () => context.read<HomeBloc>().add(const HomeResumed()),
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final day = state.day;
          return TodayView(
            title: l10n.homeTitle,
            dateLabel: day == null
                ? ''
                : MaterialLocalizations.of(context)
                      .formatFullDate(day.date.toDateTime()),
            viewState: state.viewState,
            menuTooltip: l10n.mealActions,
            errorText: l10n.homeError,
            slots: [
              if (day != null)
                for (final type in MealType.mains) _slot(context, day, type),
            ],
          );
        },
      ),
    );
  }

  MealSlotData _slot(BuildContext context, Day day, MealType type) {
    final l10n = context.l10n;
    final mr = isMarathi(context);
    final bloc = context.read<HomeBloc>();
    final meal = day.meal(type);

    MealSlotAction status(String label, MealStatus to) => MealSlotAction(
      label: label,
      onPressed: () =>
          bloc.add(HomeMealStatusChanged(type, to, from: meal.status)),
    );

    // The obvious next step; everything else goes in the menu (PRD §12).
    final primary = switch (meal.status) {
      MealStatus.planned => status(l10n.markCooked, MealStatus.cooked),
      MealStatus.cooked => status(l10n.markEaten, MealStatus.eaten),
      MealStatus.eaten || MealStatus.skipped => null,
    };
    final firstRecipe = meal.items.whereType<RecipeMealItem>().firstOrNull;

    return MealSlotData(
      title: l10n.mealType(type.name),
      dishes: [for (final item in meal.items) mealItemName(item, marathi: mr)],
      emptyText: l10n.emptyMeal,
      emptyAction: MealSlotAction(
        label: l10n.findRecipe,
        onPressed: () => context.go(AppRoutes.recipes),
      ),
      statusLabel: l10n.mealStatus(meal.status.name),
      tone: switch (meal.status) {
        MealStatus.planned => SlotTone.planned,
        MealStatus.cooked => SlotTone.cooked,
        MealStatus.eaten => SlotTone.eaten,
        MealStatus.skipped => SlotTone.skipped,
      },
      primaryAction: primary,
      menuActions: meal.isEmpty ? const [] : _menu(meal, l10n, status, bloc),
      onTap: firstRecipe == null
          ? null
          : () => context.go(AppRoutes.recipe(firstRecipe.recipeId)),
    );
  }

  List<MealSlotAction> _menu(
    Meal meal,
    AppLocalizations l10n,
    MealSlotAction Function(String, MealStatus) status,
    HomeBloc bloc,
  ) => [
    // Every other status is reachable (PRD §12), minus the primary button.
    ...switch (meal.status) {
      MealStatus.planned => [
        status(l10n.markEaten, MealStatus.eaten),
        status(l10n.markSkipped, MealStatus.skipped),
      ],
      MealStatus.cooked => [
        status(l10n.markSkipped, MealStatus.skipped),
        status(l10n.markPlanned, MealStatus.planned),
      ],
      MealStatus.eaten => [
        status(l10n.markCooked, MealStatus.cooked),
        status(l10n.markSkipped, MealStatus.skipped),
        status(l10n.markPlanned, MealStatus.planned),
      ],
      MealStatus.skipped => [
        status(l10n.markCooked, MealStatus.cooked),
        status(l10n.markEaten, MealStatus.eaten),
        status(l10n.markPlanned, MealStatus.planned),
      ],
    },
    MealSlotAction(
      label: l10n.removeMeal,
      onPressed: () => bloc.add(HomeMealRemoved(meal.type)),
    ),
  ];
}

/// Calls [onResume] when the app returns to the foreground.
class _OnResume extends StatefulWidget {
  const _OnResume({required this.onResume, required this.child});

  final VoidCallback onResume;
  final Widget child;

  @override
  State<_OnResume> createState() => _OnResumeState();
}

class _OnResumeState extends State<_OnResume> {
  late final AppLifecycleListener _listener = AppLifecycleListener(
    onResume: () => widget.onResume(),
  );

  @override
  void initState() {
    super.initState();
    _listener; // create now, not on first access
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
