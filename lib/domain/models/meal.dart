import 'package:equatable/equatable.dart';

import 'meal_item.dart';
import 'meal_status.dart';
import 'meal_type.dart';

/// One meal slot on one day: its status and the items in it.
class Meal extends Equatable {
  Meal({
    required this.type,
    required this.status,
    required List<MealItem> items,
    this.statusChangedAt,
  }) : items = List.unmodifiable(
         <MealItem>[...items]..sort((a, b) => a.order.compareTo(b.order)),
       );

  /// A slot with nothing in it yet.
  factory Meal.empty(MealType type) =>
      Meal(type: type, status: MealStatus.planned, items: const []);

  final MealType type;
  final MealStatus status;

  /// When [status] last changed; null if never set.
  final DateTime? statusChangedAt;

  /// Sorted by [MealItem.order].
  final List<MealItem> items;

  bool get isEmpty => items.isEmpty;

  bool containsRecipe(String recipeId) =>
      items.any((i) => i is RecipeMealItem && i.recipeId == recipeId);

  /// The order value for an item appended after the current ones.
  int get nextOrder => items.isEmpty ? 0 : items.last.order + 1;

  @override
  List<Object?> get props => [type, status, statusChangedAt, items];
}
