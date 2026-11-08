import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// Shown in release builds in place of a widget that failed to build,
/// instead of Flutter's grey box. The rest of the screen keeps working.
///
/// Deliberately depends on nothing above it (no Theme, no localization,
/// no MediaQuery): it can be built anywhere in the tree, even when the
/// failure is in those widgets themselves.
class ErrorFallback extends StatelessWidget {
  const ErrorFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceMuted,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Center(
          child: Icon(
            Icons.error_outline,
            color: AppColors.onSurfaceMuted,
            size: 24,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}
