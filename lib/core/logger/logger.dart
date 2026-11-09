import 'dart:developer' as developer;

import 'package:injectable/injectable.dart';

/// Thin wrapper so log output can be redirected or silenced in one place.
@singleton
class Logger {
  void info(String message, {String name = 'app'}) =>
      developer.log(message, name: name);

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = 'app',
  }) => developer.log(
    message,
    name: name,
    error: error,
    stackTrace: stackTrace,
    level: 1000,
  );
}
