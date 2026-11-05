import 'package:injectable/injectable.dart';

import 'app_environment.dart';

/// Per-environment settings. Firebase options join this once the
/// dev and prod projects exist.
class AppConfig {
  const AppConfig({required this.environment, required this.showDebugBanner});

  final AppEnvironment environment;
  final bool showDebugBanner;

  bool get isProd => environment == AppEnvironment.prod;
}

@module
abstract class AppConfigModule {
  @dev
  @singleton
  AppConfig get devConfig =>
      const AppConfig(environment: AppEnvironment.dev, showDebugBanner: true);

  @prod
  @singleton
  AppConfig get prodConfig =>
      const AppConfig(environment: AppEnvironment.prod, showDebugBanner: false);
}
