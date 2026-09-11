# Conventions

## Naming

| Type                | Convention   | Example                  |
|---------------------|--------------|--------------------------|
| Files               | `snake_case` | `user_profile_page.dart` |
| Classes             | `PascalCase` | `UserProfilePage`        |
| Variables/Functions | `camelCase`  | `getUserProfile()`       |
| Constants           | `camelCase`  | `defaultTimeout`         |
| Private             | `_prefix`    | `_internalState`         |

### Specific Patterns

| Type                    | Pattern                | Example                 |
|-------------------------|------------------------|-------------------------|
| BLoC                    | `FeatureBloc`          | `ProfileBloc`           |
| BLoC State              | `FeatureState`         | `ProfileState`          |
| BLoC Event              | `FeatureEvent`         | `ProfileEvent`          |
| Use Case                | `VerbNounUseCase`      | `GetUserProfileUseCase` |
| Repository (interface)  | `NounRepository`       | `UserRepository`        |
| Repository (impl)       | `NounRepositoryImpl`   | `UserRepositoryImpl`    |
| Data Source             | `NounRemoteDataSource` | `UserRemoteDataSource`  |
| Data transfer obj (DTO) | `NounDto`              | `UserDto`               |
| Model                   | `Noun`                 | `User`                  |

## File Structure

### Feature Module

```
lib/features/profile/
├── bloc/
│   ├── profile_bloc.dart
│   ├── profile_event.dart
│   └── profile_state.dart
├── pages/
    └── profile_page.dart
```

### Domain Entity

```dart
// packages/domain/lib/models/user.dart
class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
  });

  final String id;
  final String email;
  final String name;
}
```

### Data Model

```dart
// packages/data/lib/dtos/user_dto.dart
class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.name,
  });

  final String id;
  final String email;
  final String name;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
    UserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
    );

  Map<String, dynamic> toJson() =>
    {
      'id': id,
      'email': email,
      'name': name,
    };
}
```

### BLoC State

```dart
// Use sealed classes for states
class ProfileState {
  final ViewState loadingState;

  // Other fields...
  const ProfileState({this.loadingState = ViewState.loading});
}
```

## Imports

Order imports in groups, separated by blank lines:

```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. External packages
import 'package:flutter_bloc/flutter_bloc.dart';

// 4. Local packages
import 'package:core/core.dart';
import 'package:domain/domain.dart';

// 5. Relative imports
import '../widgets/profile_header.dart';
```

## Best Practices

### Do

- ✅ Use `const` constructors where possible
- ✅ Keep widgets small and focused
- ✅ Use widgets and not functions for UI components
- ✅ Use `Result<T>` for operations that can fail
- ✅ Write models as immutable classes
- ✅ Put business logic in use cases, not BLoCs

### Don't

- ❌ Don't put UI logic in domain layer
- ❌ Don't call repositories directly from BLoCs (use use cases)
- ❌ Don't use `dynamic` - specify types
- ❌ Don't nest widgets more than 3-4 levels deep
- ❌ Don't import `data` package from `domain` (dependency inversion)
- ❌ Don't use force-unwrap (`!.`) — promote to a local variable and null-check instead, or use `.firstOrNull`, `.where()`, etc.

## Comments

```dart
// Use single-line for brief explanations

/// Use doc comments for public APIs.
///
/// Include examples for complex functions:
/// ```dart
/// final result = await getUser('123');
/// ```
class UserRepository {}

// TODO: Brief description of what needs to be done
// FIXME: Description of bug to fix
```

## Tracker Events

### Event Naming

All tracker events follow the convention:

```
app:<feature>:<element>:<action>
```

| Part | Values | Examples |
|------|--------|---------|
| `app` | always `app` | — |
| `<feature>` | feature name | `login`, `invoices`, `home`, `dashboard`, `lifecycle` |
| `<element>` | UI element or concept | `screen`, `button`, `card`, `pdf`, `banner` |
| `<action>` | what happened | `viewed`, `tapped`, `completed`, `failed`, `dismissed` |

Examples:
- `app:login:screen:viewed`
- `app:invoices:pdf:tapped`
- `app:home:banner:dismissed`
- `app:lifecycle:session_started`

### Event Class Pattern

Events extend `TrackerEvent` (from `tracker`) and use `final class`:

```dart
// packages/features/lib/invoices/tracker/invoices_tracker_events.dart
import 'package:tracker/tracker_barrel.dart';

final class InvoicesScreenViewed extends InvoiceTrackerEvents {
  const InvoicesScreenViewed();

  @override
  String get name => 'app:invoices:screen:viewed';
}
```

### Event Location

| Event type | Location |
|------------|----------|
| Feature-specific | `packages/features/lib/<feature>/tracker/<feature>_tracker_events.dart` |
| Global / app-level | `packages/tracker/lib/events/` |

## Number Formatting / Rounding Rules

> Source of truth: [Notion – Rounding rules](https://www.notion.so/Rounding-rules-2a2ec22b91ed80cda4e0fb9b77a96224)

All formatted values are produced via helpers in `packages/localization/lib/extensions/money_formatter_extension.dart`. Thousand/decimal separators follow the device **region** locale, not the app language.

### Electricity Cost (kr)

| Value | Decimals | Examples |
|-------|----------|---------|
| ≥ 10 kr | 0 | 11 kr, 454 kr, 1 567 kr |
| < 10 kr | 2 | 9,98 kr, 4,56 kr, 1,43 kr |

Functions: `formatConsumptionCostAsMoney()`, `_formatCostNumber()` in `ElectricityCostDetailMapper`.

### Hourly Average Price (realtime detail screen, kr)

Same rules as Electricity Cost above.

### Energy Usage & Production (kWh)

| Value | Decimals | Examples |
|-------|----------|---------|
| ≥ 10 kWh | 0 | 10 kWh, 98 kWh, 2 567 kWh |
| < 10 kWh | 1 (always) | 9,7 kWh, 4,5 kWh, 2,0 kWh |

Function: `formatKwh()`. Note: below 10 always shows 1 decimal even for whole numbers (2,0 not 2).

### Spot Prices (chart headline)

The spot-price chart headline/value (dashboard spot price card + spot price
detail screen) uses market-specific decimals so the value lines up with the
chart's integer Y-axis:

| Market | Unit | Decimals | Examples |
|--------|------|----------|---------|
| SE | öre/kWh | 0 | 70 öre/kWh, 142 öre/kWh |
| FI | snt/kWh | 1 | 7,0 snt/kWh, 14,2 snt/kWh |

Implemented in `spot_price_card_mapper.dart` and `spot_price_detail_mapper.dart`
(the market decimals live in each mapper's `NumberFormat.decimalPatternDigits`).

### Live Data

| Metric | Decimals | Examples |
|--------|----------|---------|
| Effect (kW) | 2 always | 0,67 kW, 11,23 kW |
| State of Charge (battery %) | 0 | 3%, 67%, 89% |

## Testing

```
test/
├── features/
│   └── profile/
│       └── bloc/
│           └── profile_bloc_test.dart
├── unit/
│   └── usecases/
│       └── get_user_profile_test.dart
└── widget/
    └── profile_page_test.dart
```

Name test files: `*_test.dart`
Name test groups after the class/function being tested.
