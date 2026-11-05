import 'app/bootstrap.dart';
import 'core/env/app_environment.dart';

/// Default entry point (`flutter run`) uses the dev environment.
void main() => bootstrap(AppEnvironment.dev);
