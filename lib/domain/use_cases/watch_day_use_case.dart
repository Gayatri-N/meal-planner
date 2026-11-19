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

  CalendarDate today() => CalendarDate.fromDateTime(_clock.now());

  Stream<Day> call(CalendarDate date) => _days.watchDay(date);

  /// Follows *today*: switches to the new day's record when the device
  /// date changes. Two triggers:
  /// - a timer set for the next local midnight, for an app left open;
  /// - [recheck], which the UI fires when the app returns to the
  ///   foreground (timers don't run reliably while it's suspended).
  Stream<Day> watchToday({Stream<void>? recheck}) {
    StreamSubscription<Day>? daySubscription;
    StreamSubscription<void>? recheckSubscription;
    Timer? midnight;
    CalendarDate? current;
    late final StreamController<Day> controller;

    void follow() {
      final date = today();
      if (date != current) {
        current = date;
        unawaited(daySubscription?.cancel());
        daySubscription = _days
            .watchDay(date)
            .listen(controller.add, onError: controller.addError);
      }
      // (Re)arm for the next midnight, a second late so the clock has
      // certainly moved to the new date. Local DateTime handles DST.
      midnight?.cancel();
      final now = _clock.now();
      final next = DateTime(now.year, now.month, now.day + 1);
      midnight = Timer(
        next.difference(now) + const Duration(seconds: 1),
        follow,
      );
    }

    controller = StreamController<Day>(
      onListen: () {
        follow();
        recheckSubscription = recheck?.listen((_) => follow());
      },
      onCancel: () async {
        midnight?.cancel();
        await recheckSubscription?.cancel();
        await daySubscription?.cancel();
      },
    );
    return controller.stream;
  }
}
