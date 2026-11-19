import 'package:injectable/injectable.dart';

import '../../domain/models/calendar_date.dart';
import '../../domain/models/day.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/meal_status.dart';
import '../../domain/models/meal_type.dart';
import '../../domain/repositories/day_repository.dart';
import '../dtos/day_dto.dart';
import '../local/local_document_store.dart';

/// [DayRepository] on the on-device [LocalDocumentStore], until Firebase.
///
/// The Firestore version mirrors this one call for call, with the same
/// [DayDto] paths and JSON:
/// - `_store.update(collection, id, fields)` →
///   `doc.update(fields)`: dotted paths replace exactly that field, as
///   here (so `setMeal` replaces the whole slot). `update` needs the
///   document to exist, so first `doc.set({'date': id},
///   SetOptions(merge: true))`; Firestore applies the two in order, also
///   offline. Do **not** use `set(merge: true)` for the fields: it treats
///   dots literally and deep-merges, so a replace would keep old items.
/// - `deleteField` → `FieldValue.delete()`
/// - `watch` → `doc.snapshots()`, `get` → `doc.get()` (cache first)
/// - `statusChangedAt`: ISO string here → `Timestamp` there.
@LazySingleton(as: DayRepository)
class LocalDayRepository implements DayRepository {
  LocalDayRepository(this._store);

  final LocalDocumentStore _store;

  @override
  Stream<Day> watchDay(CalendarDate date) => _store
      .watch(DayDto.collection, date.key)
      .map((json) => DayDto.fromJson(date, json));

  @override
  Future<Day> getDay(CalendarDate date) async =>
      DayDto.fromJson(date, await _store.get(DayDto.collection, date.key));

  @override
  Future<void> setMeal(CalendarDate date, Meal meal) =>
      _update(date, {DayDto.slot(meal.type): DayDto.mealToJson(meal)});

  @override
  Future<void> setMealStatus(
    CalendarDate date,
    MealType type,
    MealStatus status,
    DateTime changedAt,
  ) => _update(date, {
    DayDto.status(type): status.name,
    DayDto.statusChangedAt(type): DayDto.timeToJson(changedAt),
  });

  /// Removes the slot. A day left with no meals is deleted, so no empty
  /// day documents pile up (or migrate to Firestore). Firestore: the same
  /// two steps, `update({slot: FieldValue.delete()})` then `delete()` if
  /// `slots` is empty.
  @override
  Future<void> clearMeal(CalendarDate date, MealType type) async {
    await _store.update(DayDto.collection, date.key, {
      DayDto.slot(type): deleteField,
    }, onlyIfExists: true);
    if ((await getDay(date)).meals.isEmpty) {
      await _store.delete(DayDto.collection, date.key);
    }
  }

  /// Every write also sets `date`, so each document is self-describing
  /// (useful for "this week" queries in Firestore).
  Future<void> _update(CalendarDate date, Map<String, Object?> fields) =>
      _store.update(DayDto.collection, date.key, {'date': date.key, ...fields});
}
