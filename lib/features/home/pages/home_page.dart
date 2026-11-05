import 'package:flutter/material.dart';

import '../../../design_system/views/placeholder_view.dart';
import '../../../localization/l10n.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(
      title: context.l10n.homeTitle,
      message: context.l10n.homePlaceholder,
      icon: Icons.restaurant_outlined,
    );
  }
}
