import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/logger/logger.dart';
import '../local/local_document_store.dart';

@module
abstract class DataModule {
  @lazySingleton
  AssetBundle get assetBundle => rootBundle;

  /// User data on this device until Firebase is connected. Lives in the
  /// app's documents directory (kept across updates; removed on uninstall,
  /// as the onboarding warning for guests says).
  @lazySingleton
  LocalDocumentStore localDocumentStore(Logger logger) => LocalDocumentStore(
    directory: getApplicationDocumentsDirectory,
    logger: logger,
  );
}
