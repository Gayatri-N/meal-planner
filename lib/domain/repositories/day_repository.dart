import '../models/calendar_date.dart';
import '../models/day.dart';
import '../models/meal.dart';
import '../models/meal_item.dart';
import '../models/meal_status.dart';
import '../models/meal_type.dart';

/// Per-user day records (`users/{uid}/days/{date}`, ARCHITECTURE.md §6).
///
/// Shaped like Firestore on purpose so the file-backed implementation can
/// be swapped for a Firestore one without touching use cases or UI:
/// - reads are **streams** that fire immediately from local data and again
///   on every change (Firestore `snapshots()`);
/// - writes are **field-level** (one slot, one item, one status), so two
///   devices editing different things both survive (last write wins per
///   field);
/// - write futures may never complete offline with Firestore, so callers
///   must not wait on them to update the UI (ARCHITECTURE.md §7).
abstract interface class DayRepository {
  /// Emits the day now, then after every change.
  Stream<Day> watchDay(CalendarDate date);

  /// Current value, from local data. Use for decisions inside a use case.
  Future<Day> getDay(CalendarDate date);

  /// Writes a whole slot (status, items). Used for a first item or a
  /// replace.
  Future<void> setMeal(CalendarDate date, Meal meal);

  /// Adds one item to a slot that already exists.
  Future<void> addMealItem(CalendarDate date, MealType type, MealItem item);

  Future<void> setMealStatus(
    CalendarDate date,
    MealType type,
    MealStatus status,
    DateTime changedAt,
  );

  /// Removes the slot entirely; it reads as empty afterwards.
  Future<void> clearMeal(CalendarDate date, MealType type);
}
