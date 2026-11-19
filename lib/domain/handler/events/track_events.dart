import '../../models/meal_status.dart';
import '../../models/meal_type.dart';
import '../analytics_event.dart';

/// A slot was marked cooked, eaten or skipped: `track_meal_cooked`,
/// `track_meal_eaten`, `track_meal_skipped` (CONVENTIONS.md). Moving back
/// to planned is a correction and is not logged.
final class TrackMealStatusChanged extends AnalyticsEvent {
  const TrackMealStatusChanged({
    required this.status,
    required this.mealType,
    required this.itemCount,
  }) : assert(status != MealStatus.planned, 'planned is not logged');

  final MealStatus status;
  final MealType mealType;
  final int itemCount;

  @override
  String get name => 'track_meal_${status.name}';

  @override
  Map<String, Object> get params => {
    'meal_type': mealType.name,
    'item_count': itemCount,
  };
}
