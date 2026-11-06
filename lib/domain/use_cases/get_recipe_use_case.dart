import 'package:injectable/injectable.dart';

import '../../core/helpers/app_exception.dart';
import '../../core/helpers/result.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../repositories/catalog_repository.dart';

/// A recipe plus the ingredients its lines refer to.
class RecipeDetail {
  const RecipeDetail({required this.recipe, required this.ingredients});

  final Recipe recipe;
  final Map<String, Ingredient> ingredients;
}

@injectable
class GetRecipeUseCase {
  GetRecipeUseCase(this._catalog);

  final CatalogRepository _catalog;

  Future<Result<RecipeDetail>> call(String recipeId) async {
    final result = await _catalog.load();
    return switch (result) {
      Failure(:final error) => Failure(error),
      Success(value: final catalog) => switch (catalog.recipes[recipeId]) {
        final recipe? => Success(
          RecipeDetail(
            recipe: recipe,
            ingredients: {
              for (final line in recipe.ingredientLines)
                line.ingredientId: ?catalog.ingredients[line.ingredientId],
            },
          ),
        ),
        null => Failure(
          AppException(
            kind: AppExceptionKind.notFound,
            message: 'Recipe "$recipeId" not found.',
          ),
        ),
      },
    };
  }
}
