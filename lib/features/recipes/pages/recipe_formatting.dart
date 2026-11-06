import 'package:flutter/widgets.dart';

import '../../../domain/models/recipe.dart';
import '../../../localization/l10n.dart';

/// True when the UI shows Marathi first. Recipe names come from the
/// catalog, so this picks nameMr vs nameEn.
bool isMarathi(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'mr';

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

/// Below this, a scaled amount is shown as "a little" instead of a
/// number that would round to 0.
const smallestShownQuantity = 0.1;

/// `1.5 tbsp` → `1½ tbsp`, `0.25 tsp` → `¼ tsp`, salt → `to taste`,
/// `0.04 tsp` → `a little`.
String formatAmount(double? qty, String unit, AppLocalizations l10n) {
  if (unit == toTasteUnit || qty == null) return l10n.toTaste;
  if (qty < smallestShownQuantity) return l10n.aLittle;
  final label = l10n.unitLabel(unit);
  final number = formatQuantity(qty);
  if (label == '?') return '$number $unit';
  return label.isEmpty ? number : '$number $label';
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
String formatQuantity(double qty) {
  if (qty >= 10) return qty.round().toString();
  final whole = qty.floor();
  final frac = qty - whole;
  if (frac < _fractionTolerance) return '$whole';
  if (frac > 1 - _fractionTolerance) return '${whole + 1}';
  for (final (value, glyph) in _fractions) {
    if ((frac - value).abs() < _fractionTolerance) {
      return whole == 0 ? glyph : '$whole$glyph';
    }
  }
  final rounded = (qty * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}
