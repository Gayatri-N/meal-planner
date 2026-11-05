import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/features/recipes/pages/recipe_formatting.dart';

void main() {
  group('formatQuantity', () {
    const cases = [
      (1.0, '1'),
      (0.25, '¼'),
      (0.5, '½'),
      (1.5, '1½'),
      (0.75, '¾'),
      (2.0 / 3, '⅔'),
      (0.375, '0.4'),
      (2.98, '3'),
      (150.0, '150'),
      (22.5, '23'),
    ];
    for (final (qty, expected) in cases) {
      test('$qty → $expected', () => expect(formatQuantity(qty), expected));
    }
  });
}
