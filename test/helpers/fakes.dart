import 'dart:io';

import 'package:mealplanner/core/helpers/clock.dart';
import 'package:mealplanner/core/logger/logger.dart';
import 'package:mealplanner/data/local/local_document_store.dart';
import 'package:mealplanner/domain/handler/analytics_event.dart';
import 'package:mealplanner/domain/handler/analytics_handler.dart';
import 'package:mealplanner/domain/handler/crash_handler.dart';

class FixedClock extends Clock {
  FixedClock(this.time);

  DateTime time;

  @override
  DateTime now() => time;
}

class RecordingAnalytics implements AnalyticsHandler {
  final events = <AnalyticsEvent>[];

  List<String> get names => [for (final e in events) e.name];

  @override
  void log(AnalyticsEvent event) => events.add(event);

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {}
}

class RecordingCrash implements CrashHandler {
  final errors = <Object>[];

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  }) => errors.add(error);
}

/// A store in a fresh temp directory, deleted after the test.
LocalDocumentStore tempStore({
  Directory? dir,
  void Function(void Function())? addTearDown,
}) {
  final directory = dir ?? Directory.systemTemp.createTempSync('mp_store_');
  addTearDown?.call(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });
  return LocalDocumentStore(directory: () async => directory, logger: Logger());
}
