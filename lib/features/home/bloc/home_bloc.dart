import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../design_system/view_state.dart';
import '../../../domain/models/day.dart';
import '../../../domain/models/meal_status.dart';
import '../../../domain/models/meal_type.dart';
import '../../../domain/use_cases/clear_meal_use_case.dart';
import '../../../domain/use_cases/set_meal_status_use_case.dart';
import '../../../domain/use_cases/watch_day_use_case.dart';

part 'home_event.dart';
part 'home_state.dart';

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._watchDay, this._setStatus, this._clearMeal)
    : super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomeMealStatusChanged>(
      (e, _) => _setStatus(type: e.type, status: e.status),
    );
    on<HomeMealRemoved>((e, _) => _clearMeal(type: e.type));
  }

  final WatchDayUseCase _watchDay;
  final SetMealStatusUseCase _setStatus;
  final ClearMealUseCase _clearMeal;

  /// Follows today's record; every change (here or from a recipe screen)
  /// arrives through this stream, so there is no manual refresh.
  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) =>
      emit.forEach(
        _watchDay(),
        onData: (day) => HomeState(viewState: ViewState.content, day: day),
      );
}
