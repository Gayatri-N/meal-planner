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
  void recordError(Object error, StackTrace? stackTrace, {bool fatal = false}) {
    _logger.error(
      fatal ? 'Fatal error' : 'Error',
      error: error,
      stackTrace: stackTrace,
      name: 'crash',
    );
  }
}
