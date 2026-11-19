import 'package:injectable/injectable.dart';

import '../../core/helpers/clock.dart';
import '../../core/helpers/fire_and_forget.dart';
import '../handler/crash_handler.dart';
import '../models/calendar_date.dart';
import '../models/meal_type.dart';
import '../repositories/day_repository.dart';

/// Empties a slot. In MVP this is how a planned dish is changed: remove
/// it, then add another (PRD §5; Replace with suggestions is V1).
@injectable
class ClearMealUseCase {
  ClearMealUseCase(this._days, this._clock, this._crash);

  final DayRepository _days;
  final Clock _clock;
  final CrashHandler _crash;

  void call({required MealType type, CalendarDate? date}) {
    final day = date ?? CalendarDate.fromDateTime(_clock.now());
    fireAndForget(
      _days.clearMeal(day, type),
      (e, s) => _crash.recordError(e, s, reason: 'clearMeal ${type.name}'),
    );
  }
}
