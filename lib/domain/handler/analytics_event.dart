/// A product analytics event. Names must be Firebase-valid:
/// letters, digits, underscores; start with a letter; at most 40 chars.
///
/// Concrete events live in `domain/handler/events/<feature>_events.dart`
/// and are logged from use cases only. See CONVENTIONS.md § Analytics events.
abstract class AnalyticsEvent {
  const AnalyticsEvent();

  String get name;

  Map<String, Object> get params => const {};
}
