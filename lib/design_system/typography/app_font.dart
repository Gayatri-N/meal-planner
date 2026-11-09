/// The only way to choose a font family. Never hard-code `fontFamily`.
///
/// Both use the platform default for now. When fonts are bundled
/// (one with strong Devanagari support, e.g. Mukta or Noto Sans Devanagari),
/// set [family] to the family declared in pubspec.yaml.
enum AppFont {
  /// Body and UI text, Latin and Devanagari.
  primary(null),

  /// Headlines and display text.
  display(null);

  const AppFont(this.family);

  final String? family;
}
