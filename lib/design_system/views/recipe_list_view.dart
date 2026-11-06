import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../view_state.dart';

/// One row in the recipe list, already localized.
class RecipeListItemData {
  const RecipeListItemData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.meta,
    this.badge,
  });

  final String id;
  final String title;
  final String subtitle;
  final String meta;

  /// Small label such as "Draft"; null hides it.
  final String? badge;
}

class RecipeListView extends StatelessWidget {
  const RecipeListView({
    super.key,
    required this.title,
    required this.searchHint,
    required this.viewState,
    required this.items,
    required this.emptyText,
    required this.errorText,
    required this.onQueryChanged,
    required this.onRecipeTap,
  });

  final String title;
  final String searchHint;
  final ViewState viewState;
  final List<RecipeListItemData> items;
  final String emptyText;
  final String errorText;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onRecipeTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: SearchBar(
              hintText: searchHint,
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: const WidgetStatePropertyAll(
                AppColors.surfaceMuted,
              ),
              onChanged: onQueryChanged,
            ),
          ),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) => switch (viewState) {
    ViewState.loading => const Center(child: CircularProgressIndicator()),
    ViewState.empty => _Message(text: emptyText, icon: Icons.search_off),
    ViewState.error => _Message(text: errorText, icon: Icons.error_outline),
    ViewState.content => ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) =>
          _RecipeCard(item: items[i], onTap: () => onRecipeTap(items[i].id)),
    ),
  };
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.item, required this.onTap});

  final RecipeListItemData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: theme.textTheme.titleMedium),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(item.meta, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (item.badge case final badge?) _Badge(text: badge),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: AppColors.warning),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
