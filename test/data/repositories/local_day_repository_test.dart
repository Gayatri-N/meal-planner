import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/data/dtos/day_dto.dart';
import 'package:mealplanner/data/repositories/local_day_repository.dart';
import 'package:mealplanner/domain/models/calendar_date.dart';
import 'package:mealplanner/domain/models/meal.dart';
import 'package:mealplanner/domain/models/meal_item.dart';
import 'package:mealplanner/domain/models/meal_status.dart';
import 'package:mealplanner/domain/models/meal_type.dart';

import '../../helpers/fakes.dart';

void main() {
  const date = CalendarDate(2026, 11, 9);
  // Local time in the app; stored as UTC ("…06:30:00.000Z").
  final at = DateTime.utc(2026, 11, 9, 6, 30).toLocal();

  const pithla = RecipeMealItem(
    id: 'item1',
    order: 0,
    recipeId: 'pithla',
    servings: 2,
    nameEn: 'Pithla',
    nameMr: 'पिठलं',
  );

  group('LocalDayRepository', () {
    test('round-trips a meal through the stored JSON', () async {
      final repo = LocalDayRepository(tempStore(addTearDown: addTearDown));
      final meal = Meal(
        type: MealType.lunch,
        status: MealStatus.planned,
        statusChangedAt: at,
        items: const [pithla],
      );

      await repo.setMeal(date, meal);
      await repo.addMealItem(
        date,
        MealType.lunch,
        const ManualMealItem(id: 'tea', order: 1, label: 'Tea'),
      );
      await repo.setMealStatus(date, MealType.lunch, MealStatus.eaten, at);

      final lunch = (await repo.getDay(date)).meal(MealType.lunch);
      expect(lunch.status, MealStatus.eaten);
      expect(lunch.statusChangedAt, at);
      expect(lunch.items, [
        pithla,
        const ManualMealItem(id: 'tea', order: 1, label: 'Tea'),
      ]);
    });

    test('stores exactly the Firestore document shape', () async {
      final store = tempStore(addTearDown: addTearDown);
      final repo = LocalDayRepository(store);
      await repo.setMeal(
        date,
        Meal(
          type: MealType.lunch,
          status: MealStatus.planned,
          statusChangedAt: at,
          items: const [pithla],
        ),
      );

      expect(await store.get(DayDto.collection, '2026-11-09'), {
        'date': '2026-11-09',
        'slots': {
          'lunch': {
            'status': 'planned',
            'statusChangedAt': '2026-11-09T06:30:00.000Z',
            'items': {
              'item1': {
                'kind': 'recipe',
                'order': 0,
                'recipeId': 'pithla',
                'servings': 2,
                'nameEn': 'Pithla',
                'nameMr': 'पिठलं',
              },
            },
          },
        },
      });
    });

    test(
      'setMeal replaces the old items; clearMeal empties the slot',
      () async {
        final repo = LocalDayRepository(tempStore(addTearDown: addTearDown));
        await repo.setMeal(
          date,
          Meal(
            type: MealType.lunch,
            status: MealStatus.planned,
            items: const [pithla],
          ),
        );
        const varan = RecipeMealItem(
          id: 'item2',
          order: 0,
          recipeId: 'varan',
          servings: 3,
          nameEn: 'Varan',
          nameMr: 'वरण',
        );
        await repo.setMeal(
          date,
          Meal(
            type: MealType.lunch,
            status: MealStatus.planned,
            items: const [varan],
          ),
        );
        expect((await repo.getDay(date)).meal(MealType.lunch).items, [varan]);

        await repo.clearMeal(date, MealType.lunch);
        expect((await repo.getDay(date)).meal(MealType.lunch).isEmpty, isTrue);
      },
    );

    test('watchDay emits the empty day, then each change', () async {
      final repo = LocalDayRepository(tempStore(addTearDown: addTearDown));
      final statuses = <MealStatus?>[];
      final sub = repo
          .watchDay(date)
          .listen((d) => statuses.add(d.meals[MealType.dinner]?.status));
      await Future<void>.delayed(Duration.zero);
      await repo.setMeal(
        date,
        Meal(
          type: MealType.dinner,
          status: MealStatus.planned,
          items: const [pithla],
        ),
      );
      await repo.setMealStatus(date, MealType.dinner, MealStatus.cooked, at);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(statuses, [null, MealStatus.planned, MealStatus.cooked]);
    });
  });

  group('DayDto.fromJson', () {
    test('skips what it does not understand (newer app versions)', () {
      final day = DayDto.fromJson(date, {
        'slots': {
          'brunch': {'status': 'planned'}, // unknown slot
          'lunch': {
            'status': 'teleported', // unknown status → planned
            'items': {
              'x': {'kind': 'photo'}, // unknown kind
              'y': {'kind': 'manual', 'order': 1, 'label': 'Tea'},
            },
          },
        },
      });

      expect(day.meals.keys, [MealType.lunch]);
      expect(day.meal(MealType.lunch).status, MealStatus.planned);
      expect(day.meal(MealType.lunch).items, [
        const ManualMealItem(id: 'y', order: 1, label: 'Tea'),
      ]);
    });
  });

  group('CalendarDate', () {
    test('key and parsing', () {
      expect(const CalendarDate(2026, 3, 7).key, '2026-03-07');
      expect(
        CalendarDate.tryParse('2026-03-07'),
        const CalendarDate(2026, 3, 7),
      );
      expect(CalendarDate.tryParse('2026-02-30'), isNull);
      expect(CalendarDate.tryParse('7 March'), isNull);
    });
  });
}
