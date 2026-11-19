part of 'home_bloc.dart';

class HomeState extends Equatable {
  const HomeState({this.viewState = ViewState.loading, this.day});

  final ViewState viewState;

  /// Today; null until the first read.
  final Day? day;

  @override
  List<Object?> get props => [viewState, day];
}
