import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/core/logger/logger.dart';
import 'package:mealplanner/data/local/local_document_store.dart';
import 'package:mealplanner/data/repositories/local_day_repository.dart';
import 'package:mealplanner/domain/models/calendar_date.dart';
import 'package:mealplanner/domain/models/meal.dart';
import 'package:mealplanner/domain/models/meal_item.dart';
import 'package:mealplanner/domain/models/meal_status.dart';
import 'package:mealplanner/domain/models/meal_type.dart';
import 'package:mealplanner/domain/use_cases/clear_meal_use_case.dart';
import 'package:mealplanner/domain/use_cases/set_meal_status_use_case.dart';
import 'package:mealplanner/domain/use_cases/watch_day_use_case.dart';
import 'package:mealplanner/features/home/bloc/home_bloc.dart';

import '../../helpers/fakes.dart';

void main() {
  const day1 = CalendarDate(2026, 11, 9);
  const day2 = CalendarDate(2026, 11, 10);

  late LocalDayRepository days;
  late FixedClock clock;

  setUp(() async {
    days = LocalDayRepository(LocalDocumentStore.memory(logger: Logger()));
    clock = FixedClock(DateTime(2026, 11, 9, 23, 59, 50));
    await days.setMeal(
      day1,
      Meal(
        type: MealType.lunch,
        status: MealStatus.planned,
        items: const [
          RecipeMealItem(
            id: 'i1',
            order: 0,
            recipeId: 'pithla',
            servings: 2,
            nameEn: 'Pithla',
            nameMr: 'पिठलं',
          ),
        ],
      ),
    );
  });

  HomeBloc build() {
    final crash = RecordingCrash();
    return HomeBloc(
      WatchDayUseCase(days, clock),
      SetMealStatusUseCase(days, clock, RecordingAnalytics(), crash),
      ClearMealUseCase(days, clock, crash),
    );
  }

  blocTest<HomeBloc, HomeState>(
    'acts on the day on screen, even just after midnight',
    build: build,
    act: (bloc) async {
      bloc.add(const HomeStarted());
      await Future<void>.delayed(Duration.zero);
      // Midnight passes before Home's next date check.
      clock.time = DateTime(2026, 11, 10, 0, 0, 5);
      bloc.add(const HomeMealStatusChanged(MealType.lunch, MealStatus.cooked));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    verify: (_) async {
      expect(
        (await days.getDay(day1)).meal(MealType.lunch).status,
        MealStatus.cooked,
        reason: 'the card the user tapped',
      );
      expect((await days.getDay(day2)).meals, isEmpty);
    },
  );
}
