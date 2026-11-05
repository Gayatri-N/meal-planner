# Meal Planner (working name)

Maharashtrian meal planner, recipe book, grocery assistant, and food diary. Flutter (iOS + Android) + Firebase.

Docs: [PRD](PRD.md) · [Architecture](ARCHITECTURE.md) · [Conventions](CONVENTIONS.md) · [Workplan](WORKPLAN.md) · [Costs](COSTS.md)

## Run

```sh
flutter pub get
dart run build_runner build      # DI code (lib/app/di/di.config.dart)
flutter run -t lib/main_dev.dart # dev environment (default for `flutter run`)
```

Localization code (`lib/localization/gen/`) is generated automatically on build from `lib/localization/arb/*.arb`.

## Check

```sh
flutter analyze
flutter test
```

## Status

Setup S1 done: app shell, folders, DI, routing, theme tokens, `AppFont`, EN/MR strings. Firebase (S2) is not connected yet; analytics and crash reporting log to the console.
