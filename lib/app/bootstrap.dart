import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/env/app_config.dart';
import '../core/env/app_environment.dart';
import '../design_system/components/error_fallback.dart';
import '../domain/handler/crash_handler.dart';
import 'app.dart';
import 'di/di.dart';

/// Shared entry point for every `main_*.dart`.
///
/// Firebase.initializeApp and Crashlytics join here once the Firebase
/// projects exist (Setup S2).
void bootstrap(AppEnvironment environment) {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      configureDependencies(environment);

      final crash = getIt<CrashHandler>();

      // Errors the framework caught and recovered from (build, layout,
      // paint, image decode). The app keeps running, so they are
      // non-fatal: reported with context, not counted as crashes.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        crash.recordError(
          details.exception,
          details.stack,
          reason: [
            ?details.library,
            ?details.context?.toDescription(),
          ].join(' — '),
        );
      };

      // In release, a widget that failed to build shows a small neutral
      // tile instead of a grey box. Debug keeps Flutter's red error
      // screen so problems are obvious during development.
      if (kReleaseMode) {
        ErrorWidget.builder = (_) => const ErrorFallback();
      }

      // Errors nothing else caught: the app may be in a broken state.
      PlatformDispatcher.instance.onError = (error, stack) {
        crash.recordError(error, stack, fatal: true);
        return true;
      };

      runApp(MealPlannerApp(config: getIt<AppConfig>()));
    },
    (error, stack) {
      if (getIt.isRegistered<CrashHandler>()) {
        getIt<CrashHandler>().recordError(error, stack, fatal: true);
      } else {
        debugPrint('Uncaught before DI was ready: $error\n$stack');
      }
    },
  );
}
