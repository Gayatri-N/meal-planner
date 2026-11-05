import 'package:injectable/injectable.dart';

import '../core/logger/logger.dart';
import '../domain/handler/analytics_event.dart';
import '../domain/handler/analytics_handler.dart';

/// Logs events to the console. Replaced by `FirebaseAnalyticsHandler`
/// once the Firebase projects exist.
@Singleton(as: AnalyticsHandler)
class DebugAnalyticsHandler implements AnalyticsHandler {
  DebugAnalyticsHandler(this._logger);

  final Logger _logger;
  bool _enabled = false;

  @override
  void log(AnalyticsEvent event) {
    if (!_enabled) return;
    _logger.info('${event.name} ${event.params}', name: 'analytics');
  }

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {
    _enabled = enabled;
  }
}
