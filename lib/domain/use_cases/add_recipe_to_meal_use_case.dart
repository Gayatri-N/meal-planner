import 'package:injectable/injectable.dart';

import '../../core/helpers/clock.dart';
import '../../core/helpers/fire_and_forget.dart';
import '../../core/helpers/id_generator.dart';
import '../handler/analytics_handler.dart';
import '../handler/crash_handler.dart';
import '../handler/events/plan_events.dart';
import '../models/calendar_date.dart';
import '../models/meal.dart';
import '../models/meal_item.dart';
import '../models/meal_status.dart';
import '../models/meal_type.dart';
import '../models/recipe.dart';
import '../repositories/day_repository.dart';

enum AddToMealOutcome {
  /// The slot was empty; the recipe is now on it.
  added,

  /// The slot had other items; they were replaced (`replace: true`).
  replaced,

  /// The recipe was already on that slot; nothing changed.
  alreadyThere,

  /// The slot has other items. Ask the user, then call again with
  /// `replace: true`. MVP offers Replace / Cancel; V1 adds "Add to this
  /// meal" (PRD §9).
  needsReplaceConfirmation,
}

class AddToMealResult {
  const AddToMealResult(this.outcome, this.meal);

  final AddToMealOutcome outcome;

  /// The slot before the change (for "Replace Varan with Pithla?").
  final Meal meal;
}

/// Puts a catalog recipe on a meal slot (PRD §9 slot rules).
@injectable
class AddRecipeToMealUseCase {
  AddRecipeToMealUseCase(
    this._days,
    this._clock,
    this._ids,
    this._analytics,
    this._crash,
  );

  final DayRepository _days;
  final Clock _clock;
  final IdGenerator _ids;
  final AnalyticsHandler _analytics;
  final CrashHandler _crash;

  Future<AddToMealResult> call({
    required Recipe recipe,
    required MealType type,
    required int servings,
    bool replace = false,
    CalendarDate? date,
    String source = 'recipe',
  }) async {
    final day = date ?? CalendarDate.fromDateTime(_clock.now());
    final current = (await _days.getDay(day)).meal(type);

    if (current.containsRecipe(recipe.id)) {
      return AddToMealResult(AddToMealOutcome.alreadyThere, current);
    }
    if (!current.isEmpty && !replace) {
      return AddToMealResult(
        AddToMealOutcome.needsReplaceConfirmation,
        current,
      );
    }

    final item = RecipeMealItem(
      id: _ids.next(),
      order: 0,
      recipeId: recipe.id,
      servings: servings,
      nameEn: recipe.nameEn,
      nameMr: recipe.nameMr,
    );
    // A new or replaced slot starts again as planned.
    final meal = Meal(
      type: type,
      status: MealStatus.planned,
      statusChangedAt: _clock.now(),
      items: [item],
    );
    fireAndForget(
      _days.setMeal(day, meal),
      (e, s) => _crash.recordError(e, s, reason: 'setMeal ${type.name}'),
    );
    _analytics.log(PlanRecipeAdded(mealType: type, source: source));

    return AddToMealResult(
      current.isEmpty ? AddToMealOutcome.added : AddToMealOutcome.replaced,
      current,
    );
  }
}
