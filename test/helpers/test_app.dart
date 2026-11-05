import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mealplanner/app/di/di.dart';
import 'package:mealplanner/core/env/app_environment.dart';

/// Reads assets straight from disk so loads complete inside
/// `testWidgets`' fake async zone.
class FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(File(key).readAsBytesSync()));
}

/// Configures DI for widget tests.
void configureTestDependencies() {
  configureDependencies(AppEnvironment.dev);
  getIt
    ..unregister<AssetBundle>()
    ..registerSingleton<AssetBundle>(FileAssetBundle());
}
