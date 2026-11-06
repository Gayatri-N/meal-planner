/// Application-level error with a message that is safe to show the user.
class AppException implements Exception {
  const AppException({
    required this.kind,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final AppExceptionKind kind;

  /// User-facing message. Localize at the UI edge if needed.
  final String message;

  /// Underlying error, for logging and Crashlytics only.
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException(${kind.name}): $message';
}

enum AppExceptionKind {
  /// Operation needs a connection (account link, account delete).
  networkRequired,
  permissionDenied,
  notFound,
  invalidData,
  unknown,
}
