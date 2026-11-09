import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/data/catalog/catalog_parser.dart';
import 'package:mealplanner/domain/models/meal_type.dart';
import 'package:mealplanner/domain/models/recipe.dart';

Map<String, Object?> _ingredient({
  String id = 'onion',
  String nameMr = 'कांदा',
  List<String> units = const ['pc', 'g'],
}) => {
  'id': id,
  'nameEn': 'Onion',
  'nameMr': nameMr,
  'aliases': ['kanda'],
  'category': 'vegetables',
  'commonUnits': units,
};

Map<String, Object?> _recipe({
  String id = 'test_recipe',
  List<Map<String, Object?>>? lines,
  List<String> regions = const ['pune'],
  String nameMr = 'चाचणी',
}) => {
  'id': id,
  'nameEn': 'Test recipe',
  'nameMr': nameMr,
  'mealTypes': ['breakfast'],
  'diet': 'veg',
  'baseServings': 2,
  'prepMinutes': 5,
  'cookMinutes': 10,
  'regionIds': regions,
  'contentStatus': 'draft',
  'ingredientLines':
      lines ??
      [
        {'ingredientId': 'onion', 'qty': 1, 'unit': 'pc'},
      ],
  'steps': [
    {'en': 'Cook it.', 'mr': 'शिजवा.'},
  ],
};

Map<String, Object?> _catalog({
  List<Map<String, Object?>>? ingredients,
  List<Map<String, Object?>>? recipes,
}) => {
  'catalogVersion': 1,
  'ingredients': ingredients ?? [_ingredient()],
  'recipes': recipes ?? [_recipe()],
};

void main() {
  group('parseCatalog', () {
    test('parses a valid catalog', () {
      final result = parseCatalog(_catalog());

      expect(result.issues, isEmpty);
      final recipe = result.catalog!.recipes['test_recipe']!;
      expect(recipe.mealTypes, [MealType.breakfast]);
      expect(recipe.diet, Diet.veg);
      expect(recipe.ingredientLines.single.qty, 1);
      expect(recipe.totalMinutes, 15);
    });

    test('reports an unknown ingredient id', () {
      final result = parseCatalog(
        _catalog(
          recipes: [
            _recipe(
              lines: [
                {'ingredientId': 'garlic', 'qty': 2, 'unit': 'clove'},
              ],
            ),
          ],
        ),
      );

      expect(result.catalog, isNull);
      expect(result.issues.single, contains('unknown ingredient "garlic"'));
    });

    test('reports a unit the ingredient does not allow', () {
      final result = parseCatalog(
        _catalog(
          recipes: [
            _recipe(
              lines: [
                {'ingredientId': 'onion', 'qty': 2, 'unit': 'tbsp'},
              ],
            ),
          ],
        ),
      );

      expect(result.issues.single, contains('"tbsp" is not in onion'));
    });

    test('accepts to_taste without qty and rejects it with qty', () {
      final ok = parseCatalog(
        _catalog(
          recipes: [
            _recipe(
              lines: [
                {'ingredientId': 'onion', 'unit': 'to_taste'},
              ],
            ),
          ],
        ),
      );
      final bad = parseCatalog(
        _catalog(
          recipes: [
            _recipe(
              lines: [
                {'ingredientId': 'onion', 'qty': 1, 'unit': 'to_taste'},
              ],
            ),
          ],
        ),
      );

      expect(ok.issues, isEmpty);
      expect(
        ok.catalog!.recipes['test_recipe']!.ingredientLines.single.qty,
        isNull,
      );
      expect(bad.issues.single, contains('omitted for to_taste'));
    });

    test('requires Marathi names in Devanagari', () {
      final result = parseCatalog(
        _catalog(ingredients: [_ingredient(nameMr: 'Kanda')]),
      );

      expect(result.issues.single, contains('Devanagari'));
    });

    test('reports duplicate ids and unknown regions', () {
      final result = parseCatalog(
        _catalog(
          recipes: [
            _recipe(),
            _recipe(regions: ['mumbai_street']),
          ],
        ),
      );

      expect(result.issues, contains(contains('duplicate id "test_recipe"')));
      expect(
        result.issues,
        contains(contains('unknown region "mumbai_street"')),
      );
    });

    test('rejects baseServings outside the servings range', () {
      final recipe = _recipe()..['baseServings'] = 25;
      final result = parseCatalog(_catalog(recipes: [recipe]));

      expect(result.issues.single, contains('baseServings'));
      expect(result.issues.single, contains('from 1 to 20'));
    });

    test('collects every problem, not just the first', () {
      final result = parseCatalog({
        'catalogVersion': 0,
        'ingredients': [
          {'id': 'Bad Id'},
        ],
        'recipes': <Object?>[],
      });

      expect(result.issues.length, greaterThan(3));
      expect(result.issues, contains(contains('lower_snake_case')));
      expect(result.issues, contains(contains('catalogVersion')));
    });
  });
}
