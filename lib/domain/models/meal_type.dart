/// A meal slot in the day. Snacks arrive in V1; the values exist now so
/// the data model never changes.
enum MealType {
  breakfast,
  morningSnack,
  lunch,
  eveningSnack,
  dinner;

  /// The three main meals: Home's slots in MVP, and the ones a recipe can
  /// be added to from the recipe screen. Snacks appear on Track in V1.
  static const mains = [breakfast, lunch, dinner];

  static MealType? tryParse(String value) => values.asNameMap()[value];
}
