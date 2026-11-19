import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/helpers/event_transformers.dart';
import '../../../design_system/view_state.dart';
import '../../../domain/handler/crash_handler.dart';
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
  HomeBloc(this._watchDay, this._setStatus, this._clearMeal, this._crash)
    : super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomeResumed>((_, _) => _recheck.add(null));
    // One at a time, acting on the day shown on screen (not the clock's
    // "today", which can differ right after midnight), and only from the
    // status the user saw.
    on<HomeMealStatusChanged>(
      (e, _) => _setStatus(
        type: e.type,
        status: e.status,
        from: e.from,
        date: state.day?.date,
      ),
      transformer: sequential(),
    );
    on<HomeMealRemoved>(
      (e, _) => _clearMeal(type: e.type, date: state.day?.date),
    );
  }

  final WatchDayUseCase _watchDay;
  final SetMealStatusUseCase _setStatus;
  final ClearMealUseCase _clearMeal;
  final CrashHandler _crash;
  final _recheck = StreamController<void>.broadcast();

  /// Follows today's record, switching days at midnight or on resume.
  /// Every change (here or from a recipe screen) arrives through this
  /// stream, so there is no manual refresh.
  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) =>
      emit.forEach(
        _watchDay.watchToday(recheck: _recheck.stream),
        onData: (day) => HomeState(viewState: ViewState.content, day: day),
        onError: (error, stackTrace) {
          _crash.recordError(error, stackTrace, reason: 'watchToday');
          return HomeState(viewState: ViewState.error, day: state.day);
        },
      );

  @override
  Future<void> close() async {
    await _recheck.close();
    return super.close();
  }
}
