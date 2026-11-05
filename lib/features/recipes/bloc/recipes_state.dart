part of 'recipes_bloc.dart';

class RecipesState extends Equatable {
  const RecipesState({
    this.viewState = ViewState.loading,
    this.query = '',
    this.recipes = const [],
    this.errorMessage,
  });

  final ViewState viewState;
  final String query;
  final List<Recipe> recipes;
  final String? errorMessage;

  RecipesState copyWith({
    ViewState? viewState,
    String? query,
    List<Recipe>? recipes,
    String? errorMessage,
  }) => RecipesState(
    viewState: viewState ?? this.viewState,
    query: query ?? this.query,
    recipes: recipes ?? this.recipes,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [viewState, query, recipes, errorMessage];
}
