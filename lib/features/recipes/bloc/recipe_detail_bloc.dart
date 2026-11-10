import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/helpers/app_exception.dart';
import '../../../design_system/view_state.dart';
import '../../../domain/models/meal_type.dart';
import '../../../domain/models/servings.dart';
import '../../../domain/use_cases/add_recipe_to_meal_use_case.dart';
import '../../../domain/use_cases/get_recipe_use_case.dart';

export '../../../domain/models/servings.dart' show maxServings, minServings;
export '../../../domain/use_cases/add_recipe_to_meal_use_case.dart'
    show AddToMealOutcome, AddToMealResult;

sealed class RecipeDetailEvent extends Equatable {
  const RecipeDetailEvent();

  @override
  List<Object?> get props => [];
}

final class RecipeDetailStarted extends RecipeDetailEvent {
  const RecipeDetailStarted(this.recipeId);

  final String recipeId;

  @override
  List<Object?> get props => [recipeId];
}

/// Adds [delta] (+1 / −1) to the current servings. A step rather than an
/// absolute value, so quick repeated taps each count.
final class RecipeServingsStepped extends RecipeDetailEvent {
  const RecipeServingsStepped(this.delta);

  final int delta;

  @override
  List<Object?> get props => [delta];
}

/// Put this recipe on today's [type] slot at the current servings.
/// [replace] confirms replacing whatever is there (PRD §9).
final class RecipeAddToTodayRequested extends RecipeDetailEvent {
  const RecipeAddToTodayRequested(this.type, {this.replace = false});

  final MealType type;
  final bool replace;

  @override
  List<Object?> get props => [type, replace];
}

class RecipeDetailState extends Equatable {
  const RecipeDetailState({
    this.viewState = ViewState.loading,
    this.detail,
    this.servings = 0,
    this.errorKind,
    this.lastAdd,
    this.lastAddType,
    this.addCount = 0,
  });

  final ViewState viewState;
  final RecipeDetail? detail;

  /// Servings shown. Starts at the recipe's base servings; household
  /// size becomes the default once onboarding (M2) exists.
  final int servings;

  /// Why loading failed; null unless [viewState] is error.
  final AppExceptionKind? errorKind;

  /// Result of the latest "Add to today" and the slot it targeted.
  final AddToMealResult? lastAdd;
  final MealType? lastAddType;

  /// Increments with every add result, so the page shows each snackbar
  /// or dialog exactly once (`listenWhen: addCount changed`).
  final int addCount;

  /// [errorKind] is never carried over; everything else is unless given.
  RecipeDetailState copyWith({
    ViewState? viewState,
    RecipeDetail? detail,
    int? servings,
    AppExceptionKind? errorKind,
    AddToMealResult? lastAdd,
    MealType? lastAddType,
    int? addCount,
  }) => RecipeDetailState(
    viewState: viewState ?? this.viewState,
    detail: detail ?? this.detail,
    servings: servings ?? this.servings,
    errorKind: errorKind,
    lastAdd: lastAdd ?? this.lastAdd,
    lastAddType: lastAddType ?? this.lastAddType,
    addCount: addCount ?? this.addCount,
  );

  @override
  List<Object?> get props => [
    viewState,
    detail?.recipe,
    servings,
    errorKind,
    lastAdd?.outcome,
    lastAddType,
    addCount,
  ];
}

@injectable
class RecipeDetailBloc extends Bloc<RecipeDetailEvent, RecipeDetailState> {
  RecipeDetailBloc(this._getRecipe, this._addToMeal)
    : super(const RecipeDetailState()) {
    on<RecipeDetailStarted>(_onStarted);
    on<RecipeServingsStepped>(_onServingsStepped);
    on<RecipeAddToTodayRequested>(_onAddToToday);
  }

  final GetRecipeUseCase _getRecipe;
  final AddRecipeToMealUseCase _addToMeal;

  Future<void> _onStarted(
    RecipeDetailStarted event,
    Emitter<RecipeDetailState> emit,
  ) async {
    final result = await _getRecipe(event.recipeId);
    emit(
      result.when(
        success: (detail) => RecipeDetailState(
          viewState: ViewState.content,
          detail: detail,
          servings: detail.recipe.baseServings.clamp(minServings, maxServings),
        ),
        failure: (e) =>
            RecipeDetailState(viewState: ViewState.error, errorKind: e.kind),
      ),
    );
  }

  void _onServingsStepped(
    RecipeServingsStepped event,
    Emitter<RecipeDetailState> emit,
  ) {
    if (state.detail == null) return;
    emit(
      state.copyWith(
        servings: (state.servings + event.delta).clamp(
          minServings,
          maxServings,
        ),
      ),
    );
  }

  Future<void> _onAddToToday(
    RecipeAddToTodayRequested event,
    Emitter<RecipeDetailState> emit,
  ) async {
    final detail = state.detail;
    if (detail == null) return;
    final result = await _addToMeal(
      recipe: detail.recipe,
      type: event.type,
      servings: state.servings,
      replace: event.replace,
    );
    emit(
      state.copyWith(
        lastAdd: result,
        lastAddType: event.type,
        addCount: state.addCount + 1,
      ),
    );
  }
}
