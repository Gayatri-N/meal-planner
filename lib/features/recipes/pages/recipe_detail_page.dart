import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/helpers/app_exception.dart';
import '../../../design_system/view_state.dart';
import '../../../design_system/views/recipe_detail_view.dart';
import '../../../domain/models/ingredient.dart';
import '../../../domain/models/meal_item.dart';
import '../../../domain/models/meal_type.dart';
import '../../../domain/models/recipe.dart';
import '../../../localization/l10n.dart';
import '../bloc/recipe_detail_bloc.dart';
import 'recipe_formatting.dart';

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecipeDetailBloc, RecipeDetailState>(
      listenWhen: (a, b) => a.addCount != b.addCount,
      listener: _onAddResult,
      builder: (context, state) {
        final detail = state.detail;
        if (state.viewState == ViewState.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (detail == null) {
          final message = state.errorKind == AppExceptionKind.notFound
              ? context.l10n.recipeNotFound
              : context.l10n.recipesError;
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(message)),
          );
        }
        final bloc = context.read<RecipeDetailBloc>();
        return RecipeDetailView(
          data: _data(context, detail.recipe, detail.ingredients, state),
          onDecreaseServings: () => bloc.add(const RecipeServingsStepped(-1)),
          onIncreaseServings: () => bloc.add(const RecipeServingsStepped(1)),
          onAddToToday: () => _chooseMeal(context, detail.recipe),
        );
      },
    );
  }

  /// Bottom sheet: which of today's meals? The recipe's own meal types
  /// come first.
  Future<void> _chooseMeal(BuildContext context, Recipe recipe) async {
    final l10n = context.l10n;
    final bloc = context.read<RecipeDetailBloc>();
    final options = [
      ...MealType.mains.where(recipe.mealTypes.contains),
      ...MealType.mains.where((t) => !recipe.mealTypes.contains(t)),
    ];
    final type = await showModalBottomSheet<MealType>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.chooseMealTitle,
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
            ),
            for (final t in options)
              ListTile(
                title: Text(l10n.mealType(t.name)),
                trailing: recipe.mealTypes.contains(t)
                    ? const Icon(Icons.star_outline)
                    : null,
                onTap: () => Navigator.of(sheet).pop(t),
              ),
          ],
        ),
      ),
    );
    if (type != null) bloc.add(RecipeAddToTodayRequested(type));
  }

  Future<void> _onAddResult(
    BuildContext context,
    RecipeDetailState state,
  ) async {
    final result = state.lastAdd;
    final type = state.lastAddType;
    final recipe = state.detail?.recipe;
    if (result == null || type == null || recipe == null) return;

    final l10n = context.l10n;
    final mr = isMarathi(context);
    final meal = l10n.mealType(type.name);
    final messenger = ScaffoldMessenger.of(context);

    void snack(String text, {bool showView = true}) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(text),
            action: showView
                ? SnackBarAction(
                    label: l10n.view,
                    onPressed: () => context.go('/home'),
                  )
                : null,
          ),
        );
    }

    switch (result.outcome) {
      case AddToMealOutcome.added || AddToMealOutcome.replaced:
        snack(l10n.addedToMeal(meal));
      case AddToMealOutcome.alreadyThere:
        snack(l10n.alreadyInMeal(meal));
      case AddToMealOutcome.needsReplaceConfirmation:
        final current = [
          for (final item in result.meal.items)
            switch (item) {
              RecipeMealItem() => mr ? item.nameMr : item.nameEn,
              ManualMealItem() => item.label,
            },
        ].join(' + ');
        final bloc = context.read<RecipeDetailBloc>();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: Text(l10n.replaceMealTitle(meal)),
            content: Text(
              l10n.replaceMealBody(current, mr ? recipe.nameMr : recipe.nameEn),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialog).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialog).pop(true),
                child: Text(l10n.replace),
              ),
            ],
          ),
        );
        if (confirmed ?? false) {
          bloc.add(RecipeAddToTodayRequested(type, replace: true));
        }
    }
  }

  RecipeDetailData _data(
    BuildContext context,
    Recipe recipe,
    Map<String, Ingredient> ingredients,
    RecipeDetailState state,
  ) {
    final l10n = context.l10n;
    final mr = isMarathi(context);
    final header = recipeHeader(recipe, l10n, marathi: mr);
    return RecipeDetailData(
      title: header.title,
      subtitle: header.subtitle,
      meta: header.meta,
      badge: header.badge,
      servingsLabel: l10n.recipeServings,
      servings: state.servings,
      canDecrease: state.servings > minServings,
      canIncrease: state.servings < maxServings,
      addToTodayLabel: l10n.addToToday,
      ingredientsHeading: l10n.recipeIngredients,
      ingredients: [
        for (final line in recipe.ingredientLines)
          IngredientRowData(
            name: switch (ingredients[line.ingredientId]) {
              final i? => mr ? i.nameMr : i.nameEn,
              null => line.ingredientId,
            },
            amount: formatAmount(
              line.scaledQty(
                servings: state.servings,
                baseServings: recipe.baseServings,
              ),
              line.unit,
              l10n,
            ),
            note: line.optional ? l10n.recipeOptional : null,
          ),
      ],
      stepsHeading: l10n.recipeSteps,
      steps: [for (final s in recipe.steps) mr ? s.mr : s.en],
    );
  }
}
