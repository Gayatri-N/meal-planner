import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../core/helpers/clock.dart';
import '../models/calendar_date.dart';
import '../models/day.dart';
import '../repositories/day_repository.dart';

/// Live view of one day's meals.
@injectable
class WatchDayUseCase {
  WatchDayUseCase(this._days, this._clock);

  final DayRepository _days;
  final Clock _clock;

  /// How often [watchToday] checks whether the date has changed.
  static const dateCheckInterval = Duration(minutes: 1);

  CalendarDate today() => CalendarDate.fromDateTime(_clock.now());

  Stream<Day> call(CalendarDate date) => _days.watchDay(date);

  /// Follows *today*: when the device date changes (midnight, or the app
  /// resumes on a later day), switches to the new day's record. Checks
  /// every [dateCheckInterval] rather than setting one timer for
  /// midnight, so it also recovers after the phone slept through it.
  Stream<Day> watchToday() {
    StreamSubscription<Day>? subscription;
    Timer? timer;
    CalendarDate? current;
    late final StreamController<Day> controller;

    void follow() {
      final date = today();
      if (date == current) return;
      current = date;
      unawaited(subscription?.cancel());
      subscription = _days
          .watchDay(date)
          .listen(controller.add, onError: controller.addError);
    }

    controller = StreamController<Day>(
      onListen: () {
        follow();
        timer = Timer.periodic(dateCheckInterval, (_) => follow());
      },
      onCancel: () async {
        timer?.cancel();
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }
}
