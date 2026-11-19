part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// The app came back to the foreground: the date may have changed.
final class HomeResumed extends HomeEvent {
  const HomeResumed();
}

final class HomeMealStatusChanged extends HomeEvent {
  const HomeMealStatusChanged(this.type, this.status, {required this.from});

  final MealType type;
  final MealStatus status;

  /// The status shown when the user tapped. The change only applies if
  /// the slot is still in it (guards against double taps).
  final MealStatus from;

  @override
  List<Object?> get props => [type, status, from];
}

final class HomeMealRemoved extends HomeEvent {
  const HomeMealRemoved(this.type);

  final MealType type;

  @override
  List<Object?> get props => [type];
}
