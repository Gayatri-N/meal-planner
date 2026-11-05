import 'ingredient.dart';
import 'recipe.dart';

/// The full recipe + ingredient catalog loaded on device.
class Catalog {
  Catalog({
    required this.version,
    required List<Ingredient> ingredients,
    required List<Recipe> recipes,
  }) : ingredients = {for (final i in ingredients) i.id: i},
       recipes = {for (final r in recipes) r.id: r};

  final int version;
  final Map<String, Ingredient> ingredients;
  final Map<String, Recipe> recipes;
}
