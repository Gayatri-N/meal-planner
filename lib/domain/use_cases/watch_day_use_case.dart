import 'package:injectable/injectable.dart';

import '../../core/helpers/clock.dart';
import '../models/calendar_date.dart';
import '../models/day.dart';
import '../repositories/day_repository.dart';

/// Live view of one day's meals; defaults to today on this device.
@injectable
class WatchDayUseCase {
  WatchDayUseCase(this._days, this._clock);

  final DayRepository _days;
  final Clock _clock;

  CalendarDate today() => CalendarDate.fromDateTime(_clock.now());

  Stream<Day> call({CalendarDate? date}) => _days.watchDay(date ?? today());
}
