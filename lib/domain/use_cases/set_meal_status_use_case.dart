import 'package:injectable/injectable.dart';

import '../../core/helpers/clock.dart';
import '../../core/helpers/fire_and_forget.dart';
import '../handler/analytics_handler.dart';
import '../handler/crash_handler.dart';
import '../handler/events/track_events.dart';
import '../models/calendar_date.dart';
import '../models/meal_status.dart';
import '../models/meal_type.dart';
import '../repositories/day_repository.dart';

/// Marks a whole slot planned / cooked / eaten / skipped (PRD §12).
@injectable
class SetMealStatusUseCase {
  SetMealStatusUseCase(this._days, this._clock, this._analytics, this._crash);

  final DayRepository _days;
  final Clock _clock;
  final AnalyticsHandler _analytics;
  final CrashHandler _crash;

  /// Returns false (and changes nothing) if the slot is empty or already
  /// has [status].
  Future<bool> call({
    required MealType type,
    required MealStatus status,
    CalendarDate? date,
  }) async {
    final day = date ?? CalendarDate.fromDateTime(_clock.now());
    final meal = (await _days.getDay(day)).meal(type);
    if (meal.isEmpty || !meal.status.canChangeTo(status)) return false;

    fireAndForget(
      _days.setMealStatus(day, type, status, _clock.now()),
      (e, s) => _crash.recordError(e, s, reason: 'setMealStatus ${type.name}'),
    );
    if (status != MealStatus.planned) {
      _analytics.log(
        TrackMealStatusChanged(
          status: status,
          mealType: type,
          itemCount: meal.items.length,
        ),
      );
    }
    return true;
  }
}
