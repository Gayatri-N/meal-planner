import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/helpers/app_exception.dart';
import '../../../core/helpers/event_transformers.dart';
import '../../../design_system/view_state.dart';
import '../../../domain/models/recipe.dart';
import '../../../domain/use_cases/search_recipes_use_case.dart';

part 'recipes_event.dart';
part 'recipes_state.dart';

@injectable
class RecipesBloc extends Bloc<RecipesEvent, RecipesState> {
  RecipesBloc(this._search) : super(const RecipesState()) {
    on<RecipesStarted>((event, emit) => _run('', emit));
    on<RecipesQueryChanged>(
      (event, emit) => _run(event.query, emit),
      transformer: debounceRestartable(searchDebounce),
    );
  }

  /// Pause after the last keystroke before searching.
  static const searchDebounce = Duration(milliseconds: 150);

  final SearchRecipesUseCase _search;

  Future<void> _run(String query, Emitter<RecipesState> emit) async {
    emit(
      state.copyWith(
        query: query,
        // Retrying after a failure: show progress, not the old error.
        viewState: state.viewState == ViewState.error
            ? ViewState.loading
            : null,
      ),
    );
    final result = await _search(query);
    // Stale query searches are cancelled by the transformer; this guards
    // the initial load (RecipesStarted) finishing after a typed query.
    if (state.query != query) return;
    emit(
      result.when(
        success: (recipes) => state.copyWith(
          viewState: recipes.isEmpty ? ViewState.empty : ViewState.content,
          recipes: recipes,
        ),
        failure: (e) =>
            state.copyWith(viewState: ViewState.error, errorKind: e.kind),
      ),
    );
  }
}
