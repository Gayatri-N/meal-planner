/// Outbound port for crash and error reporting. Implemented in `lib/handlers/`.
abstract interface class CrashHandler {
  void recordError(Object error, StackTrace? stackTrace, {bool fatal = false});
}
