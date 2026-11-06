part of 'recipes_bloc.dart';

sealed class RecipesEvent extends Equatable {
  const RecipesEvent();

  @override
  List<Object?> get props => [];
}

final class RecipesStarted extends RecipesEvent {
  const RecipesStarted();
}

final class RecipesQueryChanged extends RecipesEvent {
  const RecipesQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
