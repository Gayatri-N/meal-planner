import 'package:flutter/material.dart';

import '../../../design_system/views/placeholder_view.dart';
import '../../../localization/l10n.dart';

class TrackPage extends StatelessWidget {
  const TrackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(
      title: context.l10n.trackTitle,
      message: context.l10n.trackPlaceholder,
      icon: Icons.event_note_outlined,
    );
  }
}
