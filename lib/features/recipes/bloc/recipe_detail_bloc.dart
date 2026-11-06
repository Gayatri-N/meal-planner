import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/helpers/app_exception.dart';
import '../../../design_system/view_state.dart';
import '../../../domain/use_cases/get_recipe_use_case.dart';

/// Servings range offered by the stepper.
const minServings = 1;
const maxServings = 20;

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

final class RecipeServingsChanged extends RecipeDetailEvent {
  const RecipeServingsChanged(this.servings);

  final int servings;

  @override
  List<Object?> get props => [servings];
}

class RecipeDetailState extends Equatable {
  const RecipeDetailState({
    this.viewState = ViewState.loading,
    this.detail,
    this.servings = 0,
    this.errorKind,
  });

  final ViewState viewState;
  final RecipeDetail? detail;

  /// Servings shown. Starts at the recipe's base servings; household
  /// size becomes the default once onboarding (M2) exists.
  final int servings;

  /// Why loading failed; null unless [viewState] is error. Each new
  /// state is built from scratch, so it never carries an old error.
  final AppExceptionKind? errorKind;

  @override
  List<Object?> get props => [viewState, detail?.recipe, servings, errorKind];
}

@injectable
class RecipeDetailBloc extends Bloc<RecipeDetailEvent, RecipeDetailState> {
  RecipeDetailBloc(this._getRecipe) : super(const RecipeDetailState()) {
    on<RecipeDetailStarted>(_onStarted);
    on<RecipeServingsChanged>(_onServingsChanged);
  }

  final GetRecipeUseCase _getRecipe;

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
          servings: detail.recipe.baseServings,
        ),
        failure: (e) =>
            RecipeDetailState(viewState: ViewState.error, errorKind: e.kind),
      ),
    );
  }

  void _onServingsChanged(
    RecipeServingsChanged event,
    Emitter<RecipeDetailState> emit,
  ) {
    final detail = state.detail;
    if (detail == null) return;
    emit(
      RecipeDetailState(
        viewState: state.viewState,
        detail: detail,
        servings: event.servings.clamp(minServings, maxServings),
      ),
    );
  }
}
