/// A meal slot in the day. Snacks arrive in V1; the values exist now so
/// the data model never changes.
enum MealType {
  breakfast,
  morningSnack,
  lunch,
  eveningSnack,
  dinner;

  static MealType? tryParse(String value) {
    for (final type in values) {
      if (type.name == value) return type;
    }
    return null;
  }
}
