import 'package:flutter/widgets.dart';

import '../../../domain/models/meal_item.dart';
import '../../../domain/models/recipe.dart';
import '../../../localization/l10n.dart';

/// True when the UI shows Marathi first. Recipe names come from the
/// catalog, so this picks nameMr vs nameEn.
bool isMarathi(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'mr';

/// Display name of a meal item. Recipe items use the name snapshot
/// stored on the item, not the live catalog, so they show what was
/// planned (PRD §13). Used by Home and the replace dialog.
String mealItemName(MealItem item, {required bool marathi}) => switch (item) {
  RecipeMealItem() => marathi ? item.nameMr : item.nameEn,
  ManualMealItem() => item.label,
};

/// Header text shared by the recipe list and the recipe screen.
typedef RecipeHeaderText = ({
  String title,
  String subtitle,
  String meta,
  String? badge,
});

RecipeHeaderText recipeHeader(
  Recipe recipe,
  AppLocalizations l10n, {
  required bool marathi,
}) => (
  title: marathi ? recipe.nameMr : recipe.nameEn,
  subtitle: marathi ? recipe.nameEn : recipe.nameMr,
  meta: [
    l10n.recipeMinutes(recipe.totalMinutes),
    recipe.mealTypes.map((t) => l10n.mealType(t.name)).join(' / '),
  ].join(' · '),
  badge: recipe.contentStatus == ContentStatus.draft ? l10n.recipeDraft : null,
);

/// Below this (after switching to a smaller unit where one exists), an
/// amount is shown as "a little" instead of a number that rounds to 0.
const smallestShownQuantity = 0.1;

/// `1.5 tbsp` → `1½ tbsp`, `0.0625 kg` → `63 g`, `4 clove` → `4 cloves`,
/// salt → `to taste`, `0.04 tsp` → `a little`.
String formatAmount(double? qty, String unit, AppLocalizations l10n) {
  if (unit == toTasteUnit || qty == null) return l10n.toTaste;
  final (value, readableUnit) = readableAmount(qty, unit);
  final tooSmall = switch (readableUnit) {
    'g' || 'ml' => value < 1,
    _ => value < smallestShownQuantity,
  };
  if (tooSmall) return l10n.aLittle;
  final (shown, number) = _display(value);
  // Plural follows the number on screen: 1.04 shows as "1", so "1 cup".
  final label = unitLabel(readableUnit, shown, l10n);
  return label.isEmpty ? number : '$number $label';
}

/// Moves small amounts to a smaller unit so they stay readable:
/// 0.0625 kg → 62.5 g, 0.08 cup → 1.28 tbsp, 0.3 tbsp → 0.9 tsp.
(double, String) readableAmount(double qty, String unit) => switch (unit) {
  'kg' when qty < 1 => (qty * 1000, 'g'),
  'l' when qty < 1 => (qty * 1000, 'ml'),
  'cup' when qty < 0.25 => readableAmount(qty * 16, 'tbsp'),
  'tbsp' when qty < 0.5 => (qty * 3, 'tsp'),
  _ => (qty, unit),
};

/// Localized unit after a quantity; empty for pieces ("2 onions" → "2").
/// Singular up to 1 ("½ clove", "1 clove"), plural above ("1½ cloves").
String unitLabel(String unit, double qty, AppLocalizations l10n) {
  final count = qty > 1 ? 2 : 1;
  return switch (unit) {
    'pc' => '',
    'g' => l10n.unitG,
    'kg' => l10n.unitKg,
    'ml' => l10n.unitMl,
    'l' => l10n.unitL,
    'tsp' => l10n.unitTsp(count),
    'tbsp' => l10n.unitTbsp(count),
    'cup' => l10n.unitCup(count),
    'sprig' => l10n.unitSprig(count),
    'pinch' => l10n.unitPinch(count),
    'clove' => l10n.unitClove(count),
    'bunch' => l10n.unitBunch(count),
    _ => unit,
  };
}

const _fractions = [
  (0.25, '¼'),
  (0.5, '½'),
  (0.75, '¾'),
  (1 / 3, '⅓'),
  (2 / 3, '⅔'),
];

/// How close a fraction must be to ¼ ½ ¾ ⅓ ⅔ to be shown as that glyph.
/// Tight, so 0.3 stays "0.3" rather than becoming ⅓ (10% off).
const _fractionTolerance = 0.01;

/// Formats [qty] for display. Expects `qty >= smallestShownQuantity`;
/// smaller values are handled by [formatAmount].
String formatQuantity(double qty) => _display(qty).$2;

/// The rounded value shown and its text: 1.04 → (1, "1"),
/// 1.5 → (1.5, "1½"), 22.5 → (23, "23").
(double, String) _display(double qty) {
  if (qty >= 10) {
    final n = qty.round();
    return (n.toDouble(), '$n');
  }
  final whole = qty.floor();
  final frac = qty - whole;
  if (frac < _fractionTolerance) return (whole.toDouble(), '$whole');
  if (frac > 1 - _fractionTolerance) {
    return ((whole + 1).toDouble(), '${whole + 1}');
  }
  for (final (value, glyph) in _fractions) {
    if ((frac - value).abs() < _fractionTolerance) {
      return (whole + value, whole == 0 ? glyph : '$whole$glyph');
    }
  }
  final rounded = (qty * 10).round() / 10;
  return (
    rounded,
    rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString(),
  );
}
