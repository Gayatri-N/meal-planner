import 'package:equatable/equatable.dart';

/// One thing eaten in a meal slot: a catalog recipe or manual food
/// (PRD §7). A meal is a list of these, never a single recipeId.
sealed class MealItem extends Equatable {
  const MealItem({required this.id, required this.order});

  /// Stable id within the slot. Items are stored as a map keyed by id so
  /// two devices can edit different items without overwriting each other.
  final String id;

  /// Display order within the slot.
  final int order;
}

/// A catalog recipe on a slot. Names and servings are a **snapshot**
/// taken when the item was added, so later catalog edits never change
/// what history shows (PRD §13).
final class RecipeMealItem extends MealItem {
  const RecipeMealItem({
    required super.id,
    required super.order,
    required this.recipeId,
    required this.servings,
    required this.nameEn,
    required this.nameMr,
  });

  final String recipeId;
  final int servings;
  final String nameEn;
  final String nameMr;

  @override
  List<Object?> get props => [id, order, recipeId, servings, nameEn, nameMr];
}

/// Food that is not in the catalog ("Tea", "Leftover bhaji"). Adds
/// nothing to the grocery list (PRD §8). V1 UI; the model exists now.
final class ManualMealItem extends MealItem {
  const ManualMealItem({
    required super.id,
    required super.order,
    required this.label,
    this.quantityText,
  });

  final String label;
  final String? quantityText;

  @override
  List<Object?> get props => [id, order, label, quantityText];
}
