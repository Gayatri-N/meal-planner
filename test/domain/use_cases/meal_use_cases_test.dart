import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/core/helpers/id_generator.dart';
import 'package:mealplanner/data/repositories/local_day_repository.dart';
import 'package:mealplanner/domain/models/calendar_date.dart';
import 'package:mealplanner/domain/models/meal_item.dart';
import 'package:mealplanner/domain/models/meal_status.dart';
import 'package:mealplanner/domain/models/meal_type.dart';
import 'package:mealplanner/domain/models/recipe.dart';
import 'package:mealplanner/domain/use_cases/add_recipe_to_meal_use_case.dart';
import 'package:mealplanner/domain/use_cases/clear_meal_use_case.dart';
import 'package:mealplanner/domain/use_cases/set_meal_status_use_case.dart';

import '../../helpers/fakes.dart';

Recipe _recipe(String id, String en, String mr) => Recipe(
  id: id,
  nameEn: en,
  nameMr: mr,
  aliases: const [],
  mealTypes: const [MealType.lunch],
  diet: Diet.veg,
  baseServings: 2,
  prepMinutes: 0,
  cookMinutes: 0,
  regionIds: const ['pune'],
  seasonTags: const [],
  festivalTags: const [],
  occasionTags: const [],
  ingredientLines: const [],
  steps: const [],
  contentStatus: ContentStatus.draft,
);

void main() {
  final pithla = _recipe('pithla', 'Pithla', 'पिठलं');
  final varan = _recipe('varan', 'Varan', 'वरण');
  const today = CalendarDate(2026, 11, 9);

  late LocalDayRepository days;
  late FixedClock clock;
  late RecordingAnalytics analytics;
  late AddRecipeToMealUseCase add;
  late SetMealStatusUseCase setStatus;
  late ClearMealUseCase clear;

  /// Writes are fire-and-forget; let them land.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  setUp(() {
    days = LocalDayRepository(tempStore(addTearDown: addTearDown));
    clock = FixedClock(DateTime(2026, 11, 9, 12, 30));
    analytics = RecordingAnalytics();
    final crash = RecordingCrash();
    add = AddRecipeToMealUseCase(
      days,
      clock,
      IdGenerator.seeded(1),
      analytics,
      crash,
    );
    setStatus = SetMealStatusUseCase(days, clock, analytics, crash);
    clear = ClearMealUseCase(days, clock, crash);
  });

  group('AddRecipeToMealUseCase (PRD §9 slot rules)', () {
    test('empty slot: adds with a name/servings snapshot, planned', () async {
      final r = await add(recipe: pithla, type: MealType.lunch, servings: 3);
      await settle();

      expect(r.outcome, AddToMealOutcome.added);
      final lunch = (await days.getDay(today)).meal(MealType.lunch);
      expect(lunch.status, MealStatus.planned);
      final item = lunch.items.single as RecipeMealItem;
      expect(
        (item.recipeId, item.servings, item.nameEn, item.nameMr),
        ('pithla', 3, 'Pithla', 'पिठलं'),
      );
      expect(analytics.names, ['plan_recipe_added']);
    });

    test('same recipe already there: nothing changes', () async {
      await add(recipe: pithla, type: MealType.lunch, servings: 2);
      await settle();
      final r = await add(recipe: pithla, type: MealType.lunch, servings: 2);

      expect(r.outcome, AddToMealOutcome.alreadyThere);
      expect(
        (await days.getDay(today)).meal(MealType.lunch).items,
        hasLength(1),
      );
    });

    test(
      'other recipe there: asks first, replaces only when confirmed',
      () async {
        await add(recipe: varan, type: MealType.lunch, servings: 2);
        await settle();

        final ask = await add(
          recipe: pithla,
          type: MealType.lunch,
          servings: 2,
        );
        expect(ask.outcome, AddToMealOutcome.needsReplaceConfirmation);
        expect(
          (ask.meal.items.single as RecipeMealItem).nameEn,
          'Varan',
          reason: 'the dialog names what will be replaced',
        );
        await settle();
        expect(
          ((await days.getDay(today)).meal(MealType.lunch).items.single
                  as RecipeMealItem)
              .recipeId,
          'varan',
        );

        final done = await add(
          recipe: pithla,
          type: MealType.lunch,
          servings: 2,
          replace: true,
        );
        await settle();
        expect(done.outcome, AddToMealOutcome.replaced);
        expect(
          ((await days.getDay(today)).meal(MealType.lunch).items.single
                  as RecipeMealItem)
              .recipeId,
          'pithla',
        );
      },
    );

    test('a replaced slot starts again as planned', () async {
      await add(recipe: varan, type: MealType.lunch, servings: 2);
      await settle();
      await setStatus(type: MealType.lunch, status: MealStatus.eaten);
      await settle();
      await add(
        recipe: pithla,
        type: MealType.lunch,
        servings: 2,
        replace: true,
      );
      await settle();

      expect(
        (await days.getDay(today)).meal(MealType.lunch).status,
        MealStatus.planned,
      );
    });

    test('uses the device date for "today"', () async {
      clock.time = DateTime(2026, 11, 10, 0, 5); // just after midnight
      await add(recipe: pithla, type: MealType.breakfast, servings: 2);
      await settle();

      expect(
        (await days.getDay(const CalendarDate(2026, 11, 10)))
            .meal(MealType.breakfast)
            .isEmpty,
        isFalse,
      );
    });
  });

  group('SetMealStatusUseCase (PRD §12)', () {
    setUp(() async {
      await add(recipe: pithla, type: MealType.dinner, servings: 2);
      await settle();
      analytics.events.clear();
    });

    test('Planned → Cooked → Eaten, with timestamps and events', () async {
      expect(
        await setStatus(type: MealType.dinner, status: MealStatus.cooked),
        isTrue,
      );
      clock.time = DateTime(2026, 11, 9, 20);
      expect(
        await setStatus(type: MealType.dinner, status: MealStatus.eaten),
        isTrue,
      );
      await settle();

      final dinner = (await days.getDay(today)).meal(MealType.dinner);
      expect(dinner.status, MealStatus.eaten);
      expect(dinner.statusChangedAt, DateTime(2026, 11, 9, 20));
      expect(analytics.names, ['track_meal_cooked', 'track_meal_eaten']);
      expect(analytics.events.last.params, {
        'meal_type': 'dinner',
        'item_count': 1,
      });
    });

    test(
      'Planned → Eaten directly, and back to Planned to fix a mistake',
      () async {
        expect(
          await setStatus(type: MealType.dinner, status: MealStatus.eaten),
          isTrue,
        );
        await settle();
        expect(
          await setStatus(type: MealType.dinner, status: MealStatus.planned),
          isTrue,
        );
        await settle();

        expect(
          (await days.getDay(today)).meal(MealType.dinner).status,
          MealStatus.planned,
        );
        expect(analytics.names, [
          'track_meal_eaten',
        ], reason: 'undo is not logged');
      },
    );

    test('same status or empty slot: no change, no event', () async {
      expect(
        await setStatus(type: MealType.dinner, status: MealStatus.planned),
        isFalse,
      );
      expect(
        await setStatus(type: MealType.lunch, status: MealStatus.eaten),
        isFalse,
      );
      expect(analytics.events, isEmpty);
    });

    test('clear empties the slot', () async {
      clear(type: MealType.dinner);
      await settle();
      expect((await days.getDay(today)).meal(MealType.dinner).isEmpty, isTrue);
    });
  });
}
