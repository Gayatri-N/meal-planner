part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeMealStatusChanged extends HomeEvent {
  const HomeMealStatusChanged(this.type, this.status);

  final MealType type;
  final MealStatus status;

  @override
  List<Object?> get props => [type, status];
}

final class HomeMealRemoved extends HomeEvent {
  const HomeMealRemoved(this.type);

  final MealType type;

  @override
  List<Object?> get props => [type];
}
