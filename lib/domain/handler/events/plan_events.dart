import '../../models/meal_type.dart';
import '../analytics_event.dart';

/// A recipe was put on a meal slot (CONVENTIONS.md § Analytics events).
final class PlanRecipeAdded extends AnalyticsEvent {
  const PlanRecipeAdded({required this.mealType, required this.source});

  final MealType mealType;

  /// Where the user added it from, e.g. `recipe`.
  final String source;

  @override
  String get name => 'plan_recipe_added';

  @override
  Map<String, Object> get params => {
    'meal_type': mealType.name,
    'source': source,
  };
}
