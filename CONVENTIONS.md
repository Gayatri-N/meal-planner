# Conventions — [App name]

Adapted from [reference/CONVENTIONS.md](reference/CONVENTIONS.md). Dropped electricity/money rounding. Added `GAFont`, bilingual content, and Firebase Analytics event names.

Architecture: [ARCHITECTURE.md](ARCHITECTURE.md). Product: [PRD.md](PRD.md).

---

## Naming

| Type | Convention | Example |
|------|------------|---------|
| Files | `snake_case` | `recipe_detail_page.dart` |
| Classes | `PascalCase` | `RecipeDetailPage` |
| Variables / functions | `camelCase` | `getRecipe()` |
| Constants | `camelCase` | `defaultServings` |
| Private | `_prefix` | `_internalState` |

### Specific patterns

| Type | Pattern | Example |
|------|---------|---------|
| BLoC | `FeatureBloc` | `HomeBloc` |
| BLoC state | `FeatureState` | `HomeState` |
| BLoC event | `FeatureEvent` | `HomeEvent` |
| Use case | `VerbNounUseCase` | `GetTodaysMealsUseCase` |
| Repository (interface) | `NounRepository` | `RecipeRepository` |
| Repository (impl) | `NounRepositoryImpl` | `RecipeRepositoryImpl` |
| Data source | `NounRemoteDataSource` / `NounLocalDataSource` | `RecipeFirestoreDataSource` |
| DTO | `NounDto` | `RecipeDto` |
| Domain model | `Noun` | `Recipe` |
| Handler port | `NounHandler` | `AnalyticsHandler` |
| Handler impl | `NounHandlerImpl` | `FirebaseAnalyticsHandler` |

---

## Fonts

Apply **only** via the `GAFont` enum (Design System 2.0). Do not hard-code `fontFamily` strings on widgets.

```dart
Text(
  recipe.nameMr,
  style: Theme.of(context).textTheme.titleLarge?.copyWith(
    fontFamily: GAFont.primary.value, // example — match the real enum API
  ),
);
```

Put the enum in `design_system` (e.g. `lib/design_system/typography/ga_font.dart`).

---

## File structure

### Feature module

```
lib/features/home/
├── bloc/
│   ├── home_bloc.dart
│   ├── home_event.dart
│   └── home_state.dart
├── pages/
│   └── home_page.dart
└── tracker/
    └── home_tracker_events.dart
```

`home_page.dart` uses `BlocBuilder` and passes data into a view in `design_system` (props + callbacks). No business logic in the view.

### Domain vs data

```dart
// domain/lib is a folder, not a package: lib/domain/models/recipe.dart
class Recipe {
  const Recipe({
    required this.id,
    required this.nameEn,
    required this.nameMr,
    required this.aliases,
  });

  final String id;
  final String nameEn;
  final String nameMr;
  final List<String> aliases;
}
```

```dart
// lib/data/dtos/recipe_dto.dart
class RecipeDto {
  const RecipeDto({required this.id, required this.nameEn, required this.nameMr});

  final String id;
  final String nameEn;
  final String nameMr;

  factory RecipeDto.fromJson(Map<String, dynamic> json) => RecipeDto(
        id: json['id'] as String,
        nameEn: json['nameEn'] as String,
        nameMr: json['nameMr'] as String,
      );

  Recipe toDomain() => Recipe(
        id: id,
        nameEn: nameEn,
        nameMr: nameMr,
        aliases: const [],
      );
}
```

Repository **interface** lives in `domain`. **Impl** lives in `data`.

---

## BLoC state

Prefer explicit `ViewState` (loading / content / error / empty) rather than nullable soup.

```dart
enum ViewState { loading, content, empty, error }

class HomeState {
  const HomeState({
    this.loadingState = ViewState.loading,
    this.meals = const [],
    this.errorMessage,
  });

  final ViewState loadingState;
  final List<MealSlot> meals;
  final String? errorMessage;
}
```

---

## Imports

Order, groups separated by a blank line:

1. Dart SDK  
2. Flutter  
3. External packages (`flutter_bloc`, `firebase_auth`, …)  
4. Project layers (`core`, `domain`, `design_system`, …) — package or relative as appropriate  
5. Relative imports inside the feature  

---

## Localization

- UI copy: ARB `en` and `mr`
- Recipe/ingredient copy: fields on the model, not ARB
- Language mode `en+mr` shows both names (e.g. Kanda Poha / कांदे पोहे)
- Prefer established Marathi food terms over literal translation

---

## Best practices

### Do

- Use `const` constructors where possible
- Keep widgets small; use widgets, not functions, for UI pieces
- Use `Result<T>` for operations that can fail
- Immutable models
- Business logic in use cases, not BLoCs
- Scale servings and grocery aggregation in domain use cases
- Log analytics through `AnalyticsHandler`, not from `design_system`

### Don't

- Don't put UI logic in `domain`
- Don't call repositories from BLoCs (use use cases)
- Don't use `dynamic`
- Don't nest widgets more than 3–4 levels; extract
- Don't import `data` from `domain`
- Don't use force-unwrap (`!.`) — promote to a local and null-check, or `.firstOrNull`
- Don't fetch the full recipe catalog from Firestore on every screen
- Don't enable phone/SMS auth in MVP
- Don't apply fonts except through `GAFont`

---

## Comments

```dart
// Brief why, not what

/// Public API doc comments.
class RecipeRepository {}

// TODO: …
// FIXME: …
```

---

## Tracker events

All events:

```
app:<feature>:<element>:<action>
```

| Part | Values | Examples |
|------|--------|----------|
| `app` | always `app` | — |
| `<feature>` | feature name | `auth`, `home`, `recipes`, `plan`, `track`, `shopping`, `cook`, `lifecycle` |
| `<element>` | UI or concept | `screen`, `button`, `meal`, `list`, `account`, `search`, `week` |
| `<action>` | what happened | `viewed`, `tapped`, `completed`, `failed`, `generated`, `linked`, `marked_eaten` |

### Product event list

| Name | When | First needed |
|------|------|----------------|
| `app:lifecycle:session:started` | App foreground / session | MVP |
| `app:onboarding:flow:completed` | Onboarding finished | MVP |
| `app:auth:account:linked` | Google or Apple linked (`provider` param) | MVP |
| `app:auth:account:deleted` | Account deleted | MVP |
| `app:home:screen:viewed` | Home opened | MVP |
| `app:home:meal:replaced` | Replace confirmed | V1 |
| `app:cook:recommendation:shown` | Suggestions rendered | MVP (Cook Now) |
| `app:cook:recommendation:selected` | User picks a suggestion | MVP |
| `app:cook:recipe:cooked` | Mark Cooked | MVP |
| `app:track:meal:marked_eaten` | Mark Eaten (`meal_type`) | MVP |
| `app:track:meal:skipped` | Skipped | MVP |
| `app:track:manual_food:added` | Manual food on a slot | V1 |
| `app:recipes:screen:viewed` | Catalog | MVP |
| `app:recipes:search:completed` | Search submitted (`has_results` bool) | MVP |
| `app:recipes:detail:viewed` | Recipe opened (`recipe_id`) | MVP |
| `app:recipes:favourite:toggled` | Favourite on/off | V1 |
| `app:plan:recipe:added` | Recipe added to a slot | V1 |
| `app:plan:week:generated` | Generate week | V1 |
| `app:plan:week:copied` | Copy previous week | V1 |
| `app:cook:today:opened` | आज काय बनवायचं? | V1 |
| `app:cook:pantry:opened` | घरात काय आहे? | V1 |
| `app:cook:pantry:recipe:selected` | Recipe from pantry match | V1 |
| `app:shopping:list:generated` | List from plan | V1 |
| `app:shopping:item:checked` | Check-off | V1 |

Core funnel: `recommendation:shown` → `recommendation:selected` → `recipe:cooked` → `meal:marked_eaten`.

Parameters: snake_case, no PII (no email, no raw pantry dump). `recipe_id` is OK.

### Event class pattern

```dart
final class HomeScreenViewed extends AnalyticsEvent {
  const HomeScreenViewed();

  @override
  String get name => 'app:home:screen:viewed';
}
```

| Event type | Location |
|------------|----------|
| Feature-specific | `lib/features/<feature>/tracker/<feature>_tracker_events.dart` |
| App-level | `lib/domain/handler/` or `lib/handlers/` events |

---

## Testing

```
test/
├── features/
│   └── home/
│       └── bloc/
│           └── home_bloc_test.dart
├── domain/
│   └── use_cases/
│       └── mark_meal_eaten_use_case_test.dart
└── widget/
    └── home_view_test.dart
```

Name files `*_test.dart`. Name groups after the class/function under test.

---

*End of conventions.*
