import '../../domain/models/calendar_date.dart';
import '../../domain/models/day.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/meal_item.dart';
import '../../domain/models/meal_status.dart';
import '../../domain/models/meal_type.dart';

/// Converts day documents (`days/{yyyy-MM-dd}`) to and from the domain.
///
/// The JSON shape is exactly the Firestore document in ARCHITECTURE.md §6,
/// so the local store and Firestore share this code. One difference at
/// the storage edge: `statusChangedAt` is an ISO-8601 UTC string here;
/// the Firestore repository converts it to/from a `Timestamp`.
///
/// ```json
/// {
///   "date": "2026-11-09",
///   "slots": {
///     "lunch": {
///       "status": "planned",
///       "statusChangedAt": "2026-11-09T06:30:00.000Z",
///       "items": {
///         "a1b2…": { "kind": "recipe", "order": 0, "recipeId": "pithla",
///                    "servings": 2, "nameEn": "Pithla", "nameMr": "पिठलं" }
///       }
///     }
///   }
/// }
/// ```
abstract final class DayDto {
  static const collection = 'days';

  /// Firestore-style field paths, shared by every DayRepository.
  static String slot(MealType t) => 'slots.${t.name}';
  static String status(MealType t) => '${slot(t)}.status';
  static String statusChangedAt(MealType t) => '${slot(t)}.statusChangedAt';
  static String item(MealType t, String id) => '${slot(t)}.items.$id';

  /// Reads a day document; a missing document is an empty day. Unknown
  /// slots, statuses or item kinds are skipped, so data written by a
  /// newer app version never crashes an older one.
  static Day fromJson(CalendarDate date, Map<String, Object?>? json) {
    final slots = json?['slots'];
    if (slots is! Map<String, Object?>) return Day.empty(date);
    final meals = <MealType, Meal>{};
    for (final MapEntry(key: name, value: slotJson) in slots.entries) {
      final type = MealType.tryParse(name);
      final meal = type == null ? null : _meal(type, slotJson);
      if (type != null && meal != null) meals[type] = meal;
    }
    return Day(date: date, meals: meals);
  }

  // Every field is read with a type check, never a cast: a value of the
  // wrong type falls back to a default (or drops that one item), so one
  // bad field never breaks the whole day.

  static Meal? _meal(MealType type, Object? json) {
    if (json is! Map<String, Object?>) return null;
    final items = json['items'];
    return Meal(
      type: type,
      status:
          MealStatus.tryParse(_string(json['status']) ?? '') ??
          MealStatus.planned,
      // Stored in UTC; the app works in device-local time.
      statusChangedAt: DateTime.tryParse(_string(json['statusChangedAt']) ?? '')
          ?.toLocal(),
      items: [
        if (items is Map<String, Object?>)
          for (final MapEntry(key: id, value: itemJson) in items.entries)
            ?_item(id, itemJson),
      ],
    );
  }

  static MealItem? _item(String id, Object? json) {
    if (json is! Map<String, Object?>) return null;
    final order = _int(json['order']) ?? 0;
    switch (json['kind']) {
      case 'recipe':
        final recipeId = _string(json['recipeId']);
        if (recipeId == null) return null; // useless without a recipe
        final nameEn = _string(json['nameEn']) ?? recipeId;
        return RecipeMealItem(
          id: id,
          order: order,
          recipeId: recipeId,
          servings: _int(json['servings']) ?? 1,
          nameEn: nameEn,
          nameMr: _string(json['nameMr']) ?? nameEn,
        );
      case 'manual':
        final label = _string(json['label']);
        if (label == null) return null;
        return ManualMealItem(
          id: id,
          order: order,
          label: label,
          quantityText: _string(json['quantityText']),
        );
      default:
        return null;
    }
  }

  static String? _string(Object? v) => v is String && v.isNotEmpty ? v : null;

  /// Accepts whole-number doubles too: Firestore and other JSON writers
  /// may store `2` as `2.0`.
  static int? _int(Object? v) => switch (v) {
    int() => v,
    double() when v == v.roundToDouble() && v.isFinite => v.toInt(),
    _ => null,
  };

  /// A whole slot, for `update({slot(type): mealToJson(meal)})`.
  static Map<String, Object?> mealToJson(Meal meal) => {
    'status': meal.status.name,
    if (meal.statusChangedAt case final at?) 'statusChangedAt': timeToJson(at),
    'items': {for (final item in meal.items) item.id: itemToJson(item)},
  };

  static Map<String, Object?> itemToJson(MealItem item) => switch (item) {
    RecipeMealItem() => {
      'kind': 'recipe',
      'order': item.order,
      'recipeId': item.recipeId,
      'servings': item.servings,
      'nameEn': item.nameEn,
      'nameMr': item.nameMr,
    },
    ManualMealItem() => {
      'kind': 'manual',
      'order': item.order,
      'label': item.label,
      'quantityText': ?item.quantityText,
    },
  };

  static String timeToJson(DateTime time) => time.toUtc().toIso8601String();
}
