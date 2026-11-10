import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../view_state.dart';

/// Visual tone of a slot's status chip.
enum SlotTone { planned, cooked, eaten, skipped }

class MealSlotAction {
  const MealSlotAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// One meal slot on the Today screen, already localized.
class MealSlotData {
  const MealSlotData({
    required this.title,
    required this.dishes,
    required this.emptyText,
    this.statusLabel,
    this.tone = SlotTone.planned,
    this.primaryAction,
    this.menuActions = const [],
    this.emptyAction,
    this.onTap,
  });

  final String title;

  /// Dish names in order; empty when nothing is planned.
  final List<String> dishes;
  final String emptyText;
  final String? statusLabel;
  final SlotTone tone;

  /// The obvious next step (Mark cooked, then Mark eaten).
  final MealSlotAction? primaryAction;

  /// Everything else, in the ⋮ menu.
  final List<MealSlotAction> menuActions;

  /// Shown instead of actions when the slot is empty.
  final MealSlotAction? emptyAction;

  /// Opens the first dish.
  final VoidCallback? onTap;
}

class TodayView extends StatelessWidget {
  const TodayView({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.viewState,
    required this.slots,
    required this.menuTooltip,
  });

  final String title;
  final String dateLabel;
  final ViewState viewState;
  final List<MealSlotData> slots;
  final String menuTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: viewState == ViewState.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                Text(
                  dateLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final slot in slots) ...[
                  _SlotCard(slot: slot, menuTooltip: menuTooltip),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot, required this.menuTooltip});

  final MealSlotData slot;
  final String menuTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = slot.dishes.isEmpty;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: slot.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      slot.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (slot.statusLabel case final label? when !isEmpty)
                    _StatusChip(label: label, tone: slot.tone),
                  if (slot.menuActions.isNotEmpty)
                    PopupMenuButton<int>(
                      tooltip: menuTooltip,
                      icon: const Icon(Icons.more_vert),
                      onSelected: (i) => slot.menuActions[i].onPressed(),
                      itemBuilder: (_) => [
                        for (final (i, action) in slot.menuActions.indexed)
                          PopupMenuItem(value: i, child: Text(action.label)),
                      ],
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(
                  isEmpty ? slot.emptyText : slot.dishes.join(' + '),
                  style: isEmpty
                      ? theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : theme.textTheme.titleLarge?.copyWith(
                          decoration: slot.tone == SlotTone.skipped
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                ),
              ),
              if ((isEmpty ? slot.emptyAction : slot.primaryAction)
                  case final action?) ...[
                const SizedBox(height: AppSpacing.sm),
                isEmpty
                    ? OutlinedButton.icon(
                        onPressed: action.onPressed,
                        icon: const Icon(Icons.search),
                        label: Text(action.label),
                      )
                    : FilledButton.tonal(
                        onPressed: action.onPressed,
                        child: Text(action.label),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});

  final String label;
  final SlotTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      SlotTone.planned => AppColors.onSurfaceMuted,
      SlotTone.cooked => AppColors.primary,
      SlotTone.eaten => AppColors.success,
      SlotTone.skipped => AppColors.onSurfaceMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tone == SlotTone.eaten) ...[
            Icon(Icons.check, size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
