import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

class IngredientRowData {
  const IngredientRowData({
    required this.name,
    required this.amount,
    this.note,
  });

  final String name;
  final String amount;

  /// e.g. "optional"; null hides it.
  final String? note;
}

/// Everything the recipe screen shows, already localized and scaled.
class RecipeDetailData {
  const RecipeDetailData({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.servingsLabel,
    required this.servings,
    required this.canDecrease,
    required this.canIncrease,
    required this.ingredientsHeading,
    required this.ingredients,
    required this.stepsHeading,
    required this.steps,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String servingsLabel;
  final int servings;
  final bool canDecrease;
  final bool canIncrease;
  final String ingredientsHeading;
  final List<IngredientRowData> ingredients;
  final String stepsHeading;
  final List<String> steps;
  final String? badge;
}

class RecipeDetailView extends StatelessWidget {
  const RecipeDetailView({
    super.key,
    required this.data,
    required this.onDecreaseServings,
    required this.onIncreaseServings,
  });

  final RecipeDetailData data;
  final VoidCallback onDecreaseServings;
  final VoidCallback onIncreaseServings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          Text(data.title, style: theme.textTheme.headlineMedium),
          Text(
            data.subtitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(data.meta, style: theme.textTheme.bodyMedium),
              ),
              if (data.badge case final badge?)
                Text(
                  badge,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ServingsStepper(
            label: data.servingsLabel,
            servings: data.servings,
            onDecrease: data.canDecrease ? onDecreaseServings : null,
            onIncrease: data.canIncrease ? onIncreaseServings : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(data.ingredientsHeading, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final row in data.ingredients) _IngredientRow(row: row),
          const SizedBox(height: AppSpacing.lg),
          Text(data.stepsHeading, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final (i, step) in data.steps.indexed)
            _StepRow(number: i + 1, text: step),
        ],
      ),
    );
  }
}

class _ServingsStepper extends StatelessWidget {
  const _ServingsStepper({
    required this.label,
    required this.servings,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final int servings;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
          IconButton.outlined(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$servings',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
          ),
          IconButton.outlined(
            onPressed: onIncrease,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.row});

  final IngredientRowData row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: row.name,
                children: [
                  if (row.note case final note?)
                    TextSpan(
                      text: '  $note',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          Text(
            row.amount,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            child: Text(
              '$number',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
