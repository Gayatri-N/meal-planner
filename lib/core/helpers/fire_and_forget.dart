import 'dart:async';

/// Starts a write without waiting for it (ARCHITECTURE.md §7: offline
/// Firestore writes only complete when the server confirms, so the UI
/// must update from streams, not from the write's future). Errors go to
/// [onError] instead of being lost.
void fireAndForget(
  Future<void> write,
  void Function(Object error, StackTrace stackTrace) onError,
) {
  unawaited(write.then<void>((_) {}, onError: onError));
}
