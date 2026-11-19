/// Status of one meal slot (PRD §12). Applies to the whole slot, not to
/// each dish.
enum MealStatus {
  planned,
  cooked,
  eaten,
  skipped;

  /// PRD §12 allows any change to a different status without a state
  /// machine (Planned → Eaten directly; Eaten → Planned to fix a mistake).
  bool canChangeTo(MealStatus next) => next != this;

  static MealStatus? tryParse(String value) => values.asNameMap()[value];
}
