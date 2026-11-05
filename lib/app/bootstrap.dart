import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/env/app_config.dart';
import '../core/env/app_environment.dart';
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
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        crash.recordError(details.exception, details.stack, fatal: true);
      };
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
