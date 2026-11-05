import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/views/recipe_list_view.dart';
import '../../../domain/models/recipe.dart';
import '../../../localization/l10n.dart';
import '../bloc/recipes_bloc.dart';
import 'recipe_formatting.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mr = isMarathi(context);
    return BlocBuilder<RecipesBloc, RecipesState>(
      builder: (context, state) => RecipeListView(
        title: l10n.recipesTitle,
        searchHint: l10n.recipesSearchHint,
        viewState: state.viewState,
        emptyText: l10n.recipesEmpty,
        errorText: l10n.recipesError,
        items: [for (final r in state.recipes) _item(r, l10n, mr: mr)],
        onQueryChanged: (q) =>
            context.read<RecipesBloc>().add(RecipesQueryChanged(q)),
        onRecipeTap: (id) => context.go('/recipes/$id'),
      ),
    );
  }

  RecipeListItemData _item(
    Recipe r,
    AppLocalizations l10n, {
    required bool mr,
  }) => RecipeListItemData(
    id: r.id,
    title: mr ? r.nameMr : r.nameEn,
    subtitle: mr ? r.nameEn : r.nameMr,
    meta: [
      l10n.recipeMinutes(r.totalMinutes),
      r.mealTypes.map((t) => l10n.mealType(t.name)).join(' / '),
    ].join(' · '),
    badge: r.contentStatus == ContentStatus.draft ? l10n.recipeDraft : null,
  );
}
