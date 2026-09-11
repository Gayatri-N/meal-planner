# Architecture

## Overview

The app follows **Clean Architecture** with a multi-package monorepo structure managed
by [Melos](https://melos.invertase.dev/). The architecture is strictly layered with clear separation
of concerns and uses **dependency injection** via `injectable` annotations with code generation.

```
                 ┌─────────────────────────────────────┐
                 │              APP                    │
                 │  (entry point, navigation, DI)      │
                 │   Uses: go_router, get_it           │
                 └──────────────┬──────────────────────┘
                                │ orchestrates
                 ┌──────────────▼──────────────────────┐
                 │           FEATURES                  │
                 │    (BLoC, Pages, UI logic)          │
                 └──┬────────────────┬──────────────┬──┘
                    │                │              │
        ┌───────────▼───┐    ┌───────▼────────┐     │
        │ DESIGN_SYSTEM │    │    DOMAIN      │     │
        │ (UI views,    │    │  (use cases,   │     │
        │  components,  │    │   business     │     │
        │   themes)     │    │    logic)      │     │
        └───────┬───────┘    └───────┬────────┘     │
                │                    │              │
                │            ┌───────▼────────┐     │
                │            │     DATA       │     │
                │            │ (repositories, │     │
                │            │  DTOs, network,│     │
                │            │   storage)     │     │
                │            └───────┬────────┘     │
                │                    │              │
                └────────────────────┴──────────────┘
                                     │
                ┌────────────────────┼────────────────────┐
                │                                         │
           ┌────▼─────┐                           ┌───────▼────────┐
           │  CORE    │                           │  LOCALIZATION  │
           │(helpers, │                           │  (intl, phrase │
           │ env,     │                           │   OTA updates, │
           │ logger,  │                           │    l10n)       │
           │ Result)  │                           └────────────────┘
           └──────────┘

   Foundation Layer (used by all packages above)
```

## Packages

### `app` (Top Layer - `/lib`)

Application entry point and navigation setup. **Only layer with access to `GetIt` container.**

| Folder        | Purpose                                                                  |
|---------------|--------------------------------------------------------------------------|
| `app/`        | App widget, auth token provider                                          |
| `navigation/` | Go router setup, routes, native bridge                                   |
| `di/`         | DI configuration with `injectable` (`@InjectableInit`)                   |
| `handlers/`   | Adapters that implement domain outbound ports (e.g. tracker integration) |
| `main_*.dart` | Entry points for different environments                                  |

**Key Responsibilities:**

- Initialize dependency injection with environment-specific configuration
- Setup navigation with `go_router`
- Configure global error handlers
- Bridge communication with native iOS/Android apps

### `features`

Feature-specific BLoC and pages. **Contains UI logic but delegates presentation to `design_system`.
**

| Folder      | Purpose                                       |
|-------------|-----------------------------------------------|
| `invoices/` | Invoice feature (bloc, events, states, pages) |
| `di/`       | Injectable module registration                |

**Dependencies:** `flutter_bloc`, `injectable`, `domain`, `design_system`, `localization`

**Example:**

```dart
@injectable
class InvoicesBloc extends Bloc<InvoicesEvent, InvoicesState> {
  InvoicesBloc(this._getInvoicesUseCase) : super(...);

  final GetInvoicesUseCase _getInvoicesUseCase;
}
```

### `design_system`

Reusable UI components and views. **Pure presentation layer, no business logic.**

| Folder        | Purpose                                               |
|---------------|-------------------------------------------------------|
| `tokens/`     | Colors, typography, spacing constants                 |
| `components/` | Buttons, inputs, cards, charts                        |
| `views/`      | Full-page presentational views (e.g., `InvoicesView`) |
| `theme/`      | ThemeData configuration                               |
| `haptics/`    | Haptic feedback utilities                             |

**Key Principle:** Views accept data as props and delegate actions via callbacks. Used by both
production app and Widgetbook for component previews.

**Dependencies:** No injectable (stateless presentation only), `domain` for shared models, `localization` for `context.strings`

### `domain`

Pure Dart business logic and shared domain models. Uses `injectable` for use case registration.

| Folder       | Purpose                                                                    |
|--------------|----------------------------------------------------------------------------|
| `models/`    | Shared domain models (e.g. `Invoice`, `Country`, `UserIdentity`)           |
| `use_cases/` | Business operations (abstract + impl)                                      |
| `mappers/`   | DTO to domain model mapping                                                |
| `handler/`   | Outbound ports — abstract interfaces bound by the app layer (see below)    |
| `failures/`  | Domain-level error types                                                   |
| `di/`        | Injectable module registration                                             |

**Example:**

```dart
abstract class GetInvoicesUseCase {
  Stream<Result<List<Invoice>>> call({required String contractId});
}

@Singleton(as: GetInvoicesUseCase)
class GetInvoicesUseCaseImpl extends GetInvoicesUseCase {
  GetInvoicesUseCaseImpl({required InvoicesRepository repository});
// ...
}
```

**Outbound ports (`handler/`):** when a use case needs a side-effect that belongs to an outer layer (analytics, support messaging, native bridge), it depends on an abstract handler declared in `domain/lib/handler/`. The concrete adapter is registered from the app layer's `lib/handlers/`, so `domain` never imports the underlying SDK. Example: `UserIdentificationHandler` (port) is implemented by `UserIdentificationHandlerImpl` in `lib/handlers/`, which forwards to `MainTracker.identify` from `package:tracker`.

```dart
// packages/domain/lib/handler/user_identification_handler.dart
abstract interface class UserIdentificationHandler {
  void identify(UserIdentity identity);
}

// lib/handlers/user_identification_handler_impl.dart  (app layer)
@Singleton(as: UserIdentificationHandler)
class UserIdentificationHandlerImpl implements UserIdentificationHandler {
  const UserIdentificationHandlerImpl(this._tracker);
  final MainTracker _tracker;

  @override
  void identify(UserIdentity identity) =>
      _tracker.identify(UserIdentifier(/* map fields */));
}
```

**Dependencies:** `injectable`, `core`, `data`, `equatable`

### `data`

Implements domain contracts. Handles external data sources. **Uses `injectable` for repository and
module registration.**

| Folder          | Purpose                                              |
|-----------------|------------------------------------------------------|
| `repositories/` | Repository interfaces and implementations            |
| `dtos/`         | API response models (Data Transfer Objects)          |
| `network/`      | ApiClient, Dio configuration                         |
| `di/`           | Injectable modules for Dio and external dependencies |

**Example:**

```dart
@Singleton(as: InvoicesRepository)
class InvoicesRepositoryImpl implements InvoicesRepository {
  const InvoicesRepositoryImpl({required ApiClient client});
// ...
}

@module
abstract class DataModule {
  @lazySingleton
  Dio dio(AppConfig appConfig, Logger logger) {
    return Dio(BaseOptions(baseUrl: appConfig.apiBaseUrl));
  }
}
```

**Dependencies:** `dio`, `hive_flutter`, `flutter_secure_storage`, `injectable`, `core`

### `core`

Shared infrastructure for all packages. **No business logic.** Uses `injectable` for environment
configuration.

| Folder     | Purpose                                              |
|------------|------------------------------------------------------|
| `env/`     | Environment configuration (`AppConfig`, `EnvConfig`) |
| `helpers/` | `Result<T>` type, `AppException`, utilities          |
| `logger/`  | Logging infrastructure                               |
| `models/`  | Core models used across layers                       |
| `di/`      | Injectable modules for environment-specific configs  |

**Example:**

```dart
@module
abstract class CoreModule {
  @Environment('mock')
  @singleton
  AppConfig get mockAppConfig => AppConfig(const MockConfig());

  @Environment('staging')
  @singleton
  AppConfig get stagingAppConfig => AppConfig(const StagingConfig());

  @Environment('production')
  @singleton
  AppConfig get productionAppConfig => AppConfig(const ProductionConfig());
}

@singleton
class Logger {
  void log(String message, {String? name}) {
    /* ... */
  }
}
```

**Dependencies:** `injectable`, `equatable`

## Data Flow

```
Page (features/)
  → BLoC (features/, @injectable)
    → UseCase (domain/, @Singleton)
      → Repository Interface (data/)
        → Repository Impl (data/, @Singleton)
          → ApiClient (data/, @singleton)
            → Dio (@lazySingleton via @module)
```

### Example: Fetching Invoices

**1. User navigates to invoices page** (`/lib/navigation/routes/invoices_route.dart`)

```dart
GoRoute
(
path: '/invoices/:contractId',
builder: (context, state) {
final contractId = state.pathParameters['contractId']!;
return BlocProvider(
create: (_) => getIt<InvoicesBloc>()..add(InvoicesStarted(contractId)),
child: const InvoicesPage(),
);
},
)
```

**2. Page displays view with BLoC** (`features/lib/invoices/invoices_page.dart`)

```dart
class InvoicesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoicesBloc, InvoicesState>(
      builder: (context, state) {
        return InvoicesView( // from design_system
          state: state.loadingState,
          invoices: state.invoices,
          onRetry: () => context.read<InvoicesBloc>().add(InvoicesRetried()),
        );
      },
    );
  }
}
```

**3. BLoC calls use case** (`features/lib/invoices/bloc/invoices_bloc.dart`)

```dart
@injectable
class InvoicesBloc extends Bloc<InvoicesEvent, InvoicesState> {
  InvoicesBloc(this._getInvoicesUseCase) : super(...);

  final GetInvoicesUseCase _getInvoicesUseCase;

  Future<void> _onStarted(InvoicesStarted event, Emitter emit) async {
    emit(state.copyWith(loadingState: ViewState.loading));

    await emit.forEach(
      _getInvoicesUseCase(contractId: event.contractId),
      onData: (result) =>
        result.when(
          success: (invoices) =>
            state.copyWith(
              loadingState: ViewState.content,
              invoices: invoices,
            ),
          failure: (e) =>
            state.copyWith(
              loadingState: ViewState.error,
              errorMessage: e.message,
            ),
        ),
    );
  }
}
```

**4. UseCase orchestrates repository** (
`domain/lib/use_cases/invoices/get_invoice_use_case_impl.dart`)

```dart
@Singleton(as: GetInvoicesUseCase)
class GetInvoicesUseCaseImpl extends GetInvoicesUseCase {
  GetInvoicesUseCaseImpl({required InvoicesRepository repository});

  @override
  Stream<Result<List<Invoice>>> call({required String contractId}) {
    return _repository
      .fetchInvoices(contractId: contractId)
      .map((result) =>
      result.map((dtos) =>
        dtos.map((dto) => dto.toDomain()).toList()
      ));
  }
}
```

**5. Repository implementation** (`data/lib/repositories/invoices_repository_impl.dart`)

```dart
@Singleton(as: InvoicesRepository)
class InvoicesRepositoryImpl implements InvoicesRepository {
  const InvoicesRepositoryImpl({required ApiClient client});

  @override
  Stream<Result<List<InvoiceDto>>> fetchInvoices({required String contractId}) async* {
    final result = await _client.get('/v1/retail/electricity-contracts/$contractId/invoices');

    yield result.when(
      success: (data) {
        final dtos = (data['data'] as List)
          .map((json) => InvoiceDto.fromJson(json))
          .toList();
        return Success(dtos);
      },
      failure: (e) => Failure(e),
    );
  }
}
```

**6. API Client makes network call** (`data/lib/network/api_client.dart`)

```dart
@singleton
class ApiClient {
  ApiClient(this._dio);

  Future<Result<T>> get<T>(String path) async {
    try {
      final response = await _dio.get(path);
      return Success(response.data as T);
    } on DioException catch (e) {
      return Failure(AppException.fromDioError(e));
    }
  }
}
```

## Error Handling

We use `Result<T>` from `core/helpers/result.dart` instead of exceptions for expected errors:

```dart
// In repository
@Singleton(as: InvoicesRepository)
class InvoicesRepositoryImpl implements InvoicesRepository {
  Stream<Result<List<InvoiceDto>>> fetchInvoices({required String contractId}) async* {
    final result = await _client.get<Map<String, dynamic>>(endpoint);

    yield result.when(
      success: (data) {
        final dtos = (data['data'] as List)
          .map((json) => InvoiceDto.fromJson(json))
          .toList();
        return Success(dtos);
      },
      failure: (e) => Failure(e),
    );
  }
}

// In BLoC
@injectable
class InvoicesBloc extends Bloc<InvoicesEvent, InvoicesState> {
  Future<void> _onStarted(InvoicesStarted event, Emitter emit) async {
    await emit.forEach(
      _getInvoicesUseCase(contractId: event.contractId),
      onData: (result) =>
        result.when(
          success: (invoices) =>
            state.copyWith(
              loadingState: ViewState.content,
              invoices: invoices,
            ),
          failure: (e) =>
            state.copyWith(
              loadingState: ViewState.error,
              errorMessage: e.message,
            ),
        ),
    );
  }
}
```

**AppException** (`core/helpers/app_exception.dart`):

- Used for all application-level errors
- Wraps network errors, parsing errors, and business logic errors
- Contains user-friendly messages

## Environments

The app supports multiple environments with configuration managed via `injectable` annotations.

| Environment | Entry Point            | Use Case                    |
|-------------|------------------------|-----------------------------|
| Mock        | `main_mock.dart`       | Local dev with Postman mock |
| Staging     | `main_staging.dart`    | Testing against staging API |
| Production  | `main_production.dart` | Release builds              |

### Environment Configuration

**CoreModule** (`packages/core/lib/di/core_module.dart`):

```dart
@module
abstract class CoreModule {
  @Environment('mock')
  @singleton
  AppConfig get mockAppConfig => AppConfig(const MockConfig());

  @Environment('staging')
  @singleton
  AppConfig get stagingAppConfig => AppConfig(const StagingConfig());

  @Environment('production')
  @singleton
  AppConfig get productionAppConfig => AppConfig(const ProductionConfig());
}
```

**DI Initialization** (`lib/di/di.dart`):

```dart
@InjectableInit(preferRelativeImports: true)
void configureDependencies(AppEnvironment env) {
  getIt.init(environment: env.name);
}
```

**Entry Point Example** (`lib/main_staging.dart`):

```dart
Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize DI with staging environment
    configureDependencies(AppEnvironment.staging);

    final appConfig = getIt<AppConfig>();
    runApp(GreenelyApp(config: appConfig));
  }, (error, stack) {
    debugPrint('[FlutterZoneError] $error');
  });
}
```

### Environment Resolution Priority

When using `main.dart` (default entry point):

1. Native app passes environment via method channel (runtime)
2. `APP_ENV` dart-define at compile time
3. Default: staging in debug, production in release

## Dependency Injection

The app uses **injectable** with code generation for dependency injection, making DI declarative and
type-safe.

### Injectable Annotations

| Annotation             | Scope          | Use Case                                       |
|------------------------|----------------|------------------------------------------------|
| `@injectable`          | Transient      | New instance per injection (BLoCs)             |
| `@singleton`           | Singleton      | Single instance app-wide (Logger, ApiClient)   |
| `@lazySingleton`       | Lazy Singleton | Created on first use (Dio)                     |
| `@module`              | Module         | External dependencies (Dio, SharedPreferences) |
| `@Environment('name')` | Conditional    | Environment-specific configs                   |

### Code Generation

Each package with injectable dependencies has `build_runner` configured:

```yaml
# packages/*/pubspec.yaml
dev_dependencies:
  build_runner: ^2.4.13
  injectable_generator: ^2.12.1
```

**Generate dependency code:**

```bash
# Generate for all packages
melos run codegen

# Or for specific package
cd packages/data && flutter pub run build_runner build --delete-conflicting-outputs
```

### DI Setup Flow

**1. Package-level registration** - Each package registers its dependencies with annotations:

```dart
// features/lib/invoices/bloc/invoices_bloc.dart
@injectable
class InvoicesBloc extends Bloc
<...> {
InvoicesBloc(this._getInvoicesUseCase);
final GetInvoicesUseCase _getInvoicesUseCase;
}

// domain/lib/use_cases/invoices/get_invoice_use_case_impl.dart
@Singleton(as: GetInvoicesUseCase)
class GetInvoicesUseCaseImpl extends GetInvoicesUseCase {
  GetInvoicesUseCaseImpl({required InvoicesRepository repository});
}

// data/lib/repositories/invoices_repository_impl.dart
@Singleton(as: InvoicesRepository)
class InvoicesRepositoryImpl implements InvoicesRepository {
  const InvoicesRepositoryImpl({required ApiClient client});
}
```

**2. Module registration** - External dependencies use `@module`:

```dart
// data/lib/di/data_module.dart
@module
abstract class DataModule {
  @lazySingleton
  Dio dio(AppConfig appConfig, Logger logger) {
    return Dio(BaseOptions(baseUrl: appConfig.apiBaseUrl));
  }
}
```

**3. App initialization** - Top-level app initializes GetIt:

```dart
// lib/di/di.dart
@InjectableInit(preferRelativeImports: true)
void configureDependencies(AppEnvironment env) {
  getIt.init(environment: env.name);
}

// lib/main.dart
void main() {
  configureDependencies(AppEnvironment.staging);
  runApp(GreenelyApp());
}
```

**4. Usage** - Only available in app layer:

```dart
// lib/navigation/routes/invoices_route.dart
BlocProvider
(
create: (_) => getIt<InvoicesBloc>()..add(InvoicesStarted(contractId)),
child
:
const
InvoicesPage
(
)
,
)
```

### Key Dependencies

| Package                  | Purpose          | Used In              |
|--------------------------|------------------|----------------------|
| `flutter_bloc`           | State management | `features`, `app`    |
| `get_it`                 | Service locator  | `app` (only)         |
| `injectable`             | DI annotations   | All packages         |
| `injectable_generator`   | Code generation  | All packages (dev)   |
| `dio`                    | Network client   | `data`               |
| `hive_flutter`           | Local database   | `data`               |
| `flutter_secure_storage` | Secure storage   | `data`               |
| `equatable`              | Value equality   | `domain`, `features` |
| `go_router`              | Navigation       | `app`                |

## Package Dependencies Overview

| Package         | Injectable | Flutter | Dependencies                                                                             |
|-----------------|------------|---------|------------------------------------------------------------------------------------------|
| `core`          | ✅          | ✅       | `injectable`, `equatable`                                                                |
| `data`          | ✅          | ✅       | `dio`, `hive_flutter`, `flutter_secure_storage`, `injectable`, `core`                    |
| `domain`        | ✅          | ❌       | `injectable`, `core`, `data`, `equatable`                                                |
| `design_system` | ❌          | ✅       | `flutter_svg`, `cached_network_image`, `fl_chart`, `core`, `domain`, `localization`      |
| `features`      | ✅          | ✅       | `flutter_bloc`, `injectable`, `core`, `domain`, `design_system`, `localization`           |
| `app`           | ✅          | ✅       | `get_it`, `injectable`, `go_router`, `flutter_bloc`, `core`, `features`, `design_system` |

**Key Points:**

- **Injectable**: Uses `@injectable`, `@singleton`, `@module` annotations with code generation
- **Flutter**: Has Flutter SDK dependency (`domain` is pure Dart)
- Only `app` has access to `GetIt` container - all other packages use injectable annotations

## Apps

### `widgetbook`

Interactive catalog for previewing design system components in isolation.

```bash
# Run widgetbook
melos run widgetbook
# Or directly:
cd apps/widgetbook && fvm flutter run -d chrome
```

| Folder                        | Purpose                                             |
|-------------------------------|-----------------------------------------------------|
| `lib/`                        | Use case definitions for each token/component       |
| `lib/views/`                  | Full-page view prototypes (e.g., invoices, devices) |
| `lib/helpers/`                | Shared helpers (device preview, auth widgets, etc.) |
| `lib/docs/`                   | Documentation pages (introduction, changelog)       |
| `lib/main.directories.g.dart` | Generated widgetbook structure                      |

Uses `widgetbook_annotation` with build_runner for code generation.

**Key conventions:**
- Views use view data models (e.g. `InvoiceViewData`) — not domain models directly
- Mock data is defined as private `final _mock*` lists using view data model types (e.g., `InvoiceViewData`)
- Domain models live in `packages/domain/lib/models/`
- View data models are colocated with their views in `design_system`
