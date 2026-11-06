part of 'recipes_bloc.dart';

class RecipesState extends Equatable {
  const RecipesState({
    this.viewState = ViewState.loading,
    this.query = '',
    this.recipes = const [],
    this.errorKind,
  });

  final ViewState viewState;
  final String query;
  final List<Recipe> recipes;

  /// Why the last load failed; null unless [viewState] is error.
  final AppExceptionKind? errorKind;

  /// [errorKind] is not carried over: every new state starts without an
  /// error unless one is passed in.
  RecipesState copyWith({
    ViewState? viewState,
    String? query,
    List<Recipe>? recipes,
    AppExceptionKind? errorKind,
  }) => RecipesState(
    viewState: viewState ?? this.viewState,
    query: query ?? this.query,
    recipes: recipes ?? this.recipes,
    errorKind: errorKind,
  );

  @override
  List<Object?> get props => [viewState, query, recipes, errorKind];
}
