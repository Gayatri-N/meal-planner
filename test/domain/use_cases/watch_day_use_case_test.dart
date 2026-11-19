import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/core/logger/logger.dart';
import 'package:mealplanner/data/local/local_document_store.dart';
import 'package:mealplanner/data/repositories/local_day_repository.dart';
import 'package:mealplanner/domain/models/calendar_date.dart';
import 'package:mealplanner/domain/models/day.dart';
import 'package:mealplanner/domain/use_cases/watch_day_use_case.dart';

import '../../helpers/fakes.dart';

void main() {
  const nov9 = CalendarDate(2026, 11, 9);
  const nov10 = CalendarDate(2026, 11, 10);

  WatchDayUseCase useCase(FixedClock clock) => WatchDayUseCase(
    LocalDayRepository(LocalDocumentStore.memory(logger: Logger())),
    clock,
  );

  test('switches to the new day at midnight (app left open)', () {
    fakeAsync((async) {
      final clock = FixedClock(DateTime(2026, 11, 9, 23, 59, 30));
      final seen = <CalendarDate>[];
      final sub = useCase(clock)
          .watchToday()
          .listen((Day d) => seen.add(d.date));
      async.flushMicrotasks();
      expect(seen, [nov9]);

      // The midnight timer is set for 30 s + 1 s from now.
      clock.time = DateTime(2026, 11, 10, 0, 0, 1);
      async.elapse(const Duration(seconds: 31));
      expect(seen.last, nov10);

      // No polling: nothing else happens for the rest of the day.
      final count = seen.length;
      async.elapse(const Duration(hours: 12));
      expect(seen, hasLength(count));

      sub.cancel();
    });
  });

  test('re-checks the date when asked (app resumed on a later day)', () {
    fakeAsync((async) {
      final clock = FixedClock(DateTime(2026, 11, 9, 22));
      final recheck = StreamController<void>();
      final seen = <CalendarDate>[];
      final sub = useCase(clock)
          .watchToday(recheck: recheck.stream)
          .listen((d) => seen.add(d.date));
      async.flushMicrotasks();

      // Suspended overnight: the midnight timer never ran. On resume:
      clock.time = DateTime(2026, 11, 10, 7, 30);
      recheck.add(null);
      async.flushMicrotasks();
      expect(seen, [nov9, nov10]);

      // A recheck on the same day changes nothing.
      recheck.add(null);
      async.flushMicrotasks();
      expect(seen, [nov9, nov10]);

      sub.cancel();
      recheck.close();
    });
  });
}
