import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/view_state.dart';
import '../../../design_system/views/recipe_detail_view.dart';
import '../../../domain/models/ingredient.dart';
import '../../../domain/models/recipe.dart';
import '../../../localization/l10n.dart';
import '../bloc/recipe_detail_bloc.dart';
import 'recipe_formatting.dart';

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecipeDetailBloc, RecipeDetailState>(
      builder: (context, state) {
        final detail = state.detail;
        if (state.viewState == ViewState.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (detail == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(context.l10n.recipesError)),
          );
        }
        final bloc = context.read<RecipeDetailBloc>();
        return RecipeDetailView(
          data: _data(context, detail.recipe, detail.ingredients, state),
          onDecreaseServings: () =>
              bloc.add(RecipeServingsChanged(state.servings - 1)),
          onIncreaseServings: () =>
              bloc.add(RecipeServingsChanged(state.servings + 1)),
        );
      },
    );
  }

  RecipeDetailData _data(
    BuildContext context,
    Recipe recipe,
    Map<String, Ingredient> ingredients,
    RecipeDetailState state,
  ) {
    final l10n = context.l10n;
    final mr = isMarathi(context);
    return RecipeDetailData(
      title: mr ? recipe.nameMr : recipe.nameEn,
      subtitle: mr ? recipe.nameEn : recipe.nameMr,
      meta: [
        l10n.recipeMinutes(recipe.totalMinutes),
        recipe.mealTypes.map((t) => l10n.mealType(t.name)).join(' / '),
      ].join(' · '),
      badge: recipe.contentStatus == ContentStatus.draft
          ? l10n.recipeDraft
          : null,
      servingsLabel: l10n.recipeServings,
      servings: state.servings,
      canDecrease: state.servings > minServings,
      canIncrease: state.servings < maxServings,
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
