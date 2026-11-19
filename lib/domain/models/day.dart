import 'package:equatable/equatable.dart';

import 'calendar_date.dart';
import 'meal.dart';
import 'meal_type.dart';

/// Everything for one date. The single source for planning, tracking and
/// history: history is simply days in the past (ARCHITECTURE.md §6).
class Day extends Equatable {
  const Day({required this.date, required this.meals});

  factory Day.empty(CalendarDate date) => Day(date: date, meals: const {});

  final CalendarDate date;

  /// Only slots that have been used. Missing slots read as empty.
  final Map<MealType, Meal> meals;

  Meal meal(MealType type) => meals[type] ?? Meal.empty(type);

  @override
  List<Object?> get props => [date, meals];
}
