import 'package:injectable/injectable.dart';

/// Current time, injectable so tests can fix "today".
@lazySingleton
class Clock {
  DateTime now() => DateTime.now();
}
