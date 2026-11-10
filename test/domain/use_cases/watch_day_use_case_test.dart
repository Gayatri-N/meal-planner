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
  test('watchToday switches to the new day after midnight', () {
    fakeAsync((async) {
      final clock = FixedClock(DateTime(2026, 11, 9, 23, 59, 30));
      final useCase = WatchDayUseCase(
        LocalDayRepository(LocalDocumentStore.memory(logger: Logger())),
        clock,
      );
      final seen = <CalendarDate>[];
      final sub = useCase.watchToday().listen((Day d) => seen.add(d.date));

      async.flushMicrotasks();
      expect(seen, [const CalendarDate(2026, 11, 9)]);

      // Midnight passes; the next check picks up the new date.
      clock.time = DateTime(2026, 11, 10, 0, 0, 10);
      async.elapse(WatchDayUseCase.dateCheckInterval);
      expect(seen.last, const CalendarDate(2026, 11, 10));

      // Same date on later checks: no re-subscription, no extra events.
      final count = seen.length;
      async.elapse(WatchDayUseCase.dateCheckInterval * 3);
      expect(seen, hasLength(count));

      sub.cancel();
    });
  });
}
