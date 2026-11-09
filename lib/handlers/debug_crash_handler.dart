import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../core/logger/logger.dart';
import '../domain/handler/crash_handler.dart';

/// Logs errors to the console. Replaced by a Crashlytics handler
/// once the Firebase projects exist.
@Singleton(as: CrashHandler)
class DebugCrashHandler implements CrashHandler {
  DebugCrashHandler(this._logger);

  final Logger _logger;

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  }) {
    final title = [
      fatal ? 'Fatal error' : 'Non-fatal error',
      ?reason,
    ].join(': ');
    _logger.error(title, error: error, stackTrace: stackTrace, name: 'crash');
    // bootstrap's PlatformDispatcher.onError returns true, which stops
    // Flutter printing uncaught errors itself. Print them here so they
    // still show up in the `flutter run` terminal, not only in DevTools.
    if (fatal && kDebugMode) {
      debugPrint('[$title] $error\n$stackTrace');
    }
  }
}
