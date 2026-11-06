import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../../core/env/app_environment.dart';
import 'di.config.dart';

/// The DI container. Only the `app` layer reads it; every other layer
/// receives dependencies through constructors.
final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies(AppEnvironment environment) =>
    getIt.init(environment: environment.name);
