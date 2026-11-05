import 'package:flutter/painting.dart';

/// Colour tokens. Warm, homely palette: turmeric/saffron accent,
/// curry-leaf green secondary, off-white paper background.
abstract final class AppColors {
  static const primary = Color(0xFFC2410C); // saffron
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF3F6212); // curry leaf
  static const onSecondary = Color(0xFFFFFFFF);

  static const background = Color(0xFFFFFBF5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF5EFE6);
  static const onSurface = Color(0xFF1C1917);
  static const onSurfaceMuted = Color(0xFF78716C);
  static const border = Color(0xFFE7E0D6);

  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
  static const error = Color(0xFFB91C1C);
}
