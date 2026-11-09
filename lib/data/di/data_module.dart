import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

@module
abstract class DataModule {
  @lazySingleton
  AssetBundle get assetBundle => rootBundle;
}
