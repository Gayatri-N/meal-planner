# Conventions — [App name]

Architecture: [ARCHITECTURE.md](ARCHITECTURE.md). Product: [PRD.md](PRD.md).

**Source of truth:** this file owns **naming, code patterns, and the analytics event list**.

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
| Data source | `Noun<Source>DataSource` | `DayFirestoreDataSource`, `CatalogAssetDataSource` |
| DTO | `NounDto` | `RecipeDto` |
| Domain model | `Noun` | `Recipe`, `Meal`, `MealItem` |
| Handler port | `NounHandler` | `AnalyticsHandler` |
| Handler impl | `<Vendor>NounHandler` | `FirebaseAnalyticsHandler` |
| Analytics event | `FeatureElementAction` | `TrackMealEaten` |

---

## Fonts

Apply **only** via the `GAFont` enum. Do not hard-code `fontFamily` strings on widgets.

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
└── pages/
    └── home_page.dart
```

`home_page.dart` uses `BlocBuilder` and passes data into a view in `design_system` (props + callbacks). No business logic in the view.

### Domain vs data

```dart
// lib/domain/models/recipe.dart
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
  const RecipeDto({
    required this.id,
    required this.nameEn,
    required this.nameMr,
    required this.aliases,
  });

  final String id;
  final String nameEn;
  final String nameMr;
  final List<String> aliases;

  factory RecipeDto.fromJson(Map<String, dynamic> json) => RecipeDto(
        id: json['id'] as String,
        nameEn: json['nameEn'] as String,
        nameMr: json['nameMr'] as String,
        aliases: (json['aliases'] as List<dynamic>? ?? const [])
            .cast<String>(),
      );

  Recipe toDomain() => Recipe(
        id: id,
        nameEn: nameEn,
        nameMr: nameMr,
        aliases: aliases,
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
    this.hasPendingWrites = false,
    this.errorMessage,
  });

  final ViewState loadingState;
  final List<Meal> meals;
  final bool hasPendingWrites; // drives the quiet "waiting to sync" indicator
  final String? errorMessage;
}
```

---

## Firestore writes

- Do **not** `await` user-data writes in BLoCs or use cases that drive UI. Fire, attach error logging, and rely on the snapshot stream (see [ARCHITECTURE.md §7](ARCHITECTURE.md#7-firestore-offline-implementation-rules))
- Use field-level `update()` with dotted paths; no transactions for user data
- Collections of things the user edits (meal items, shopping lines) are **maps keyed by id**, not arrays

---

## Imports

Order, groups separated by a blank line:

1. Dart SDK
2. Flutter
3. External packages (`flutter_bloc`, `firebase_auth`, …)
4. Project layers (`core`, `domain`, `design_system`, …) — `package:` imports
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
- Log analytics from use cases through `AnalyticsHandler`

### Don't

- Don't put UI logic in `domain`
- Don't call repositories from BLoCs (use use cases)
- Don't use `dynamic` outside JSON parsing at the DTO boundary
- Don't nest widgets more than 3–4 levels; extract
- Don't import `data` from `domain`
- Don't use force-unwrap (`!.`) — promote to a local and null-check, or `.firstOrNull`
- Don't fetch the recipe catalog from Firestore on screens — use the in-memory catalog
- Don't enable phone/SMS auth through V1
- Don't apply fonts except through `GAFont`
- Don't log analytics from widgets, pages, BLoCs, or `design_system`

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

## Analytics events

Firebase Analytics event names must be **letters, digits, and underscores only**, start with a letter, and be **≤ 40 characters**. Do not use the reserved prefixes `firebase_`, `google_`, `ga_`. Parameter names follow the same rule; ≤ 25 parameters per event.

All events:

```
<feature>_<element>_<action>
```

| Part | Values | Examples |
|------|--------|----------|
| `<feature>` | feature name | `auth`, `onboarding`, `recipes`, `plan`, `track`, `shopping`, `cook`, `pantry` |
| `<element>` | UI or concept | `account`, `meal`, `list`, `item`, `search`, `week`, `recommendation` |
| `<action>` | past tense | `completed`, `generated`, `linked`, `eaten`, `selected`, `checked` |

**Screens** are not custom events. Log `logScreenView(screenName: ...)` from the router observer (`home`, `recipes`, `recipe_detail`, `cook_today`, `pantry`, `plan`, `track`, `shopping`). Sessions use Firebase's automatic `session_start` / `app_open`.

### Product event list

| Name | When | Params | First needed |
|------|------|--------|--------------|
| `onboarding_flow_completed` | Onboarding finished | `language`, `diet`, `household_size` | MVP |
| `auth_account_linked` | Google or Apple linked | `provider` | MVP |
| `auth_link_conflict` | Provider already owns another account | `provider` | MVP |
| `auth_account_deleted` | Account deleted | — | MVP |
| `recipes_search_completed` | Search submitted | `has_results`, `query_length` | MVP |
| `recipes_detail_viewed` | Recipe opened | `recipe_id`, `source` (`search` / `home` / `cook` / `plan` / `pantry` / `list`) | MVP |
| `plan_recipe_added` | Recipe added to a slot | `meal_type`, `source` | MVP |
| `cook_recommendation_shown` | Suggestions rendered | `meal_type`, `count`, `used_pantry` | MVP |
| `cook_recommendation_selected` | User picks a suggestion | `meal_type`, `rank`, `recipe_id` | MVP |
| `track_meal_cooked` | Mark Cooked (slot) | `meal_type`, `item_count` | MVP |
| `track_meal_eaten` | Mark Eaten (slot) | `meal_type`, `item_count` | MVP |
| `track_meal_skipped` | Skipped | `meal_type` | MVP |
| `plan_meal_replaced` | Replace confirmed | `meal_type`, `rank`, `source` (`home` / `plan`) | V1 |
| `track_manual_food_added` | Manual food on a slot | `meal_type` | V1 |
| `recipes_favourite_toggled` | Favourite on/off | `recipe_id`, `is_favourite` | V1 |
| `plan_week_generated` | Generate week | — | V1 |
| `plan_week_copied` | Copy previous week | — | V1 |
| `pantry_recipe_selected` | Recipe from pantry match | `recipe_id`, `missing_count` | V1 |
| `shopping_list_generated` | List built/updated from plan | `line_count` | V1 |
| `shopping_item_checked` | Check-off | `source` (`derived` / `manual`) | V1 |

Core funnel: `cook_recommendation_shown` → `cook_recommendation_selected` → `track_meal_cooked` → `track_meal_eaten`.

Search success = `recipes_search_completed` followed by `recipes_detail_viewed` with `source = search`.

Parameters: snake_case, no PII (no email, no names, no raw pantry dump). `recipe_id` is OK.

### Event class pattern

```dart
// lib/domain/handler/analytics_event.dart
abstract class AnalyticsEvent {
  const AnalyticsEvent();
  String get name;
  Map<String, Object> get params => const {};
}

// lib/domain/handler/events/track_events.dart
final class TrackMealEaten extends AnalyticsEvent {
  const TrackMealEaten({required this.mealType, required this.itemCount});

  final String mealType;
  final int itemCount;

  @override
  String get name => 'track_meal_eaten';

  @override
  Map<String, Object> get params => {
        'meal_type': mealType,
        'item_count': itemCount,
      };
}
```

All event classes live in `lib/domain/handler/events/<feature>_events.dart`. They are logged from use cases, and `domain` cannot import `features`, so events do not live in feature folders.

Add a unit test that asserts every event name matches `^[a-zA-Z][a-zA-Z0-9_]{0,39}$`.

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
