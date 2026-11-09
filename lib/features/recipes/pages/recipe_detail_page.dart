import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/helpers/app_exception.dart';
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
