/// Outbound port for crash and error reporting. Implemented in `lib/handlers/`.
abstract interface class CrashHandler {
  /// [fatal]: the error escaped every handler and the app may be broken.
  /// Errors the framework recovered from (a widget failed to build or lay
  /// out) are non-fatal: reported and grouped, but not counted as crashes.
  ///
  /// [reason] is short context, e.g. which library or widget failed.
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  });
}
