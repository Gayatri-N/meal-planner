import 'package:equatable/equatable.dart';

import 'meal_type.dart';

/// Unit for amounts that are not measured ("salt to taste").
const toTasteUnit = 'to_taste';

/// A catalog recipe. Shared by all users; never edited by the client.
class Recipe extends Equatable {
  const Recipe({
    required this.id,
    required this.nameEn,
    required this.nameMr,
    required this.aliases,
    required this.mealTypes,
    required this.diet,
    required this.baseServings,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.regionIds,
    required this.seasonTags,
    required this.festivalTags,
    required this.occasionTags,
    required this.ingredientLines,
    required this.steps,
    required this.contentStatus,
    this.imageAsset,
  });

  final String id;
  final String nameEn;
  final String nameMr;
  final List<String> aliases;
  final List<MealType> mealTypes;
  final Diet diet;

  /// Servings the [ingredientLines] quantities are written for.
  final int baseServings;

  final int prepMinutes;
  final int cookMinutes;

  /// One or more regions; Maharashtra is not one cuisine.
  final List<String> regionIds;
  final List<String> seasonTags;
  final List<String> festivalTags;
  final List<String> occasionTags;

  final List<RecipeIngredientLine> ingredientLines;
  final List<RecipeStep> steps;

  /// Where the recipe is in the content pipeline (PRD §28, WORKPLAN).
  final ContentStatus contentStatus;

  final String? imageAsset;

  int get totalMinutes => prepMinutes + cookMinutes;

  @override
  List<Object?> get props => [id];
}

class RecipeIngredientLine extends Equatable {
  const RecipeIngredientLine({
    required this.ingredientId,
    required this.qty,
    required this.unit,
    this.optional = false,
  });

  final String ingredientId;

  /// Null only when [unit] is [toTasteUnit].
  final double? qty;
  final String unit;
  final bool optional;

  /// `scaledQty = recipeQty × (itemServings / recipeBaseServings)` (PRD §14).
  /// Returns null for unmeasured amounts.
  double? scaledQty({required int servings, required int baseServings}) {
    final q = qty;
    if (q == null) return null;
    return q * servings / baseServings;
  }

  @override
  List<Object?> get props => [ingredientId, qty, unit, optional];
}

class RecipeStep extends Equatable {
  const RecipeStep({required this.en, required this.mr});

  final String en;
  final String mr;

  @override
  List<Object?> get props => [en, mr];
}

enum Diet {
  veg,
  egg,
  nonVeg;

  static Diet? tryParse(String value) {
    for (final d in values) {
      if (d.name == value) return d;
    }
    return null;
  }
}

enum ContentStatus {
  /// Written, not yet cooked or reviewed. Never ship to production.
  draft,

  /// Cooked once; quantities verified.
  tested,

  /// Marathi reviewed and approved for release.
  reviewed;

  static ContentStatus? tryParse(String value) {
    for (final s in values) {
      if (s.name == value) return s;
    }
    return null;
  }
}
