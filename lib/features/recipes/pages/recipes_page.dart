import 'package:flutter/material.dart';

import '../../../design_system/views/placeholder_view.dart';
import '../../../localization/l10n.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(
      title: context.l10n.recipesTitle,
      message: context.l10n.recipesPlaceholder,
      icon: Icons.menu_book_outlined,
    );
  }
}
