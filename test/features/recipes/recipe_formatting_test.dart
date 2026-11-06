import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/features/recipes/pages/recipe_formatting.dart';
import 'package:mealplanner/localization/l10n.dart';

void main() {
  group('formatQuantity', () {
    const cases = [
      (1.0, '1'),
      (0.25, '¼'),
      (0.5, '½'),
      (1.5, '1½'),
      (0.75, '¾'),
      (1.0 / 3, '⅓'),
      (2.0 / 3, '⅔'),
      // Close to a fraction but not equal: show the number, not the glyph.
      (0.3, '0.3'),
      (0.7, '0.7'),
      (0.375, '0.4'),
      (2.98, '3'),
      (150.0, '150'),
      (22.5, '23'),
    ];
    for (final (qty, expected) in cases) {
      test('$qty → $expected', () => expect(formatQuantity(qty), expected));
    }
  });

  group('formatAmount', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final mr = lookupAppLocalizations(const Locale('mr'));

    test('adds the localized unit', () {
      expect(formatAmount(1.5, 'tbsp', en), '1½ tbsp');
      expect(formatAmount(2, 'pc', en), '2');
      expect(formatAmount(1, 'pinch', mr), '1 चिमूट');
    });

    test('shows "a little" instead of rounding a tiny amount to 0', () {
      // ¼ tsp in a 6-serving recipe, viewed for 1 serving.
      final tiny = 0.25 * 1 / 6;
      expect(formatAmount(tiny, 'tsp', en), 'a little');
      expect(formatAmount(tiny, 'tsp', mr), 'थोडंसं');
    });

    test('to_taste ignores the quantity', () {
      expect(formatAmount(null, 'to_taste', en), 'to taste');
    });
  });
}
