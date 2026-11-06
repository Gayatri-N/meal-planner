import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/domain/models/recipe.dart';

void main() {
  group('RecipeIngredientLine.scaledQty', () {
    const line = RecipeIngredientLine(
      ingredientId: 'poha',
      qty: 150,
      unit: 'g',
    );

    test('scales by itemServings / baseServings', () {
      expect(line.scaledQty(servings: 4, baseServings: 2), 300);
      expect(line.scaledQty(servings: 3, baseServings: 2), 225);
      expect(line.scaledQty(servings: 1, baseServings: 2), 75);
    });

    test('returns null for to_taste amounts', () {
      const salt = RecipeIngredientLine(
        ingredientId: 'salt',
        qty: null,
        unit: toTasteUnit,
      );
      expect(salt.scaledQty(servings: 4, baseServings: 2), isNull);
    });
  });
}
