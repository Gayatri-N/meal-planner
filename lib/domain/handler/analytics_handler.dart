import 'analytics_event.dart';

/// Outbound port for product analytics. Implemented in `lib/handlers/`.
abstract interface class AnalyticsHandler {
  void log(AnalyticsEvent event);

  /// Turns collection on or off (consent). Off until the user agrees
  /// where consent is required.
  Future<void> setCollectionEnabled({required bool enabled});
}
