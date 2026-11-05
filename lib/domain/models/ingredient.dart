import 'package:equatable/equatable.dart';

/// A catalog ingredient. Grocery and pantry join on [id], never on names.
class Ingredient extends Equatable {
  const Ingredient({
    required this.id,
    required this.nameEn,
    required this.nameMr,
    required this.aliases,
    required this.category,
    required this.commonUnits,
  });

  final String id;
  final String nameEn;
  final String nameMr;

  /// Transliterations and alternative spellings, for search.
  final List<String> aliases;

  final IngredientCategory category;

  /// Units recipes may use for this ingredient (e.g. `g`, `tsp`, `pc`).
  final List<String> commonUnits;

  @override
  List<Object?> get props => [id];
}

enum IngredientCategory {
  grains,
  pulses,
  vegetables,
  fruits,
  herbs,
  spices,
  nuts,
  oils,
  dairy,
  staples;

  static IngredientCategory? tryParse(String value) {
    for (final c in values) {
      if (c.name == value) return c;
    }
    return null;
  }
}
