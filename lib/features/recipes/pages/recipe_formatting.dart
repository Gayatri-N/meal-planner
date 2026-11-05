import 'package:flutter/widgets.dart';

import '../../../domain/models/recipe.dart';
import '../../../localization/l10n.dart';

/// True when the UI shows Marathi first. Recipe names come from the
/// catalog, so this picks nameMr vs nameEn.
bool isMarathi(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'mr';

/// `1.5 tbsp` → `1½ tbsp`, `0.25 tsp` → `¼ tsp`, salt → `to taste`.
String formatAmount(double? qty, String unit, AppLocalizations l10n) {
  if (unit == toTasteUnit || qty == null) return l10n.toTaste;
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

String formatQuantity(double qty) {
  if (qty >= 10) return qty.round().toString();
  final whole = qty.floor();
  final frac = qty - whole;
  if (frac < 0.05) return '$whole';
  if (frac > 0.95) return '${whole + 1}';
  for (final (value, glyph) in _fractions) {
    if ((frac - value).abs() < 0.04) {
      return whole == 0 ? glyph : '$whole$glyph';
    }
  }
  final rounded = (qty * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}
