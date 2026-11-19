import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mealplanner/app/di/di.dart';
import 'package:mealplanner/core/env/app_environment.dart';
import 'package:mealplanner/core/logger/logger.dart';
import 'package:mealplanner/data/local/local_document_store.dart';

/// Reads assets straight from disk so loads complete inside
/// `testWidgets`' fake async zone. [overrides] replaces an asset's
/// content by key (e.g. a test catalog).
class FileAssetBundle extends CachingAssetBundle {
  FileAssetBundle({this.overrides = const {}});

  final Map<String, String> overrides;

  @override
  Future<ByteData> load(String key) async {
    final override = overrides[key];
    final bytes = override != null
        ? utf8.encode(override)
        : File(key).readAsBytesSync();
    return ByteData.sublistView(bytes);
  }
}

/// Configures DI for widget tests: assets from disk, user data in memory.
void configureTestDependencies({Map<String, String> assets = const {}}) {
  configureDependencies(AppEnvironment.dev);
  getIt
    ..unregister<AssetBundle>()
    ..registerSingleton<AssetBundle>(FileAssetBundle(overrides: assets))
    ..unregister<LocalDocumentStore>()
    ..registerSingleton(LocalDocumentStore.memory(logger: Logger()));
}
