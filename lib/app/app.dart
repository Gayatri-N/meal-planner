import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/env/app_config.dart';
import '../design_system/theme/app_theme.dart';
import '../localization/l10n.dart';
import 'navigation/app_router.dart';

class MealPlannerApp extends StatefulWidget {
  const MealPlannerApp({super.key, required this.config, this.locale});

  final AppConfig config;

  /// Forces a UI locale. Null follows the device; the in-app language
  /// setting (onboarding, M2) will drive this.
  final Locale? locale;

  @override
  State<MealPlannerApp> createState() => _MealPlannerAppState();
}

class _MealPlannerAppState extends State<MealPlannerApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: widget.config.showDebugBanner,
      theme: AppTheme.light(),
      locale: widget.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: _router,
    );
  }
}
