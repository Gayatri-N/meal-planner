import 'dart:async';

/// BLoC event transformer for search-as-you-type: waits until no new event
/// has arrived for [duration], then handles the latest one. If a newer
/// event gets through while a handler is still running, that handler is
/// cancelled, so stale results are never emitted.
///
/// Signature matches `EventTransformer<E>` from package:bloc, so it can be
/// passed as `on<E>(handler, transformer: debounceRestartable(...))`.
Stream<E> Function(Stream<E> events, Stream<E> Function(E) mapper)
debounceRestartable<E>(Duration duration) =>
    (events, mapper) => _switchMap(_debounced(events, duration), mapper);

Stream<E> _debounced<E>(Stream<E> source, Duration duration) {
  Timer? timer;
  StreamSubscription<E>? subscription;
  late final StreamController<E> controller;

  controller = StreamController<E>(
    onListen: () {
      subscription = source.listen(
        (event) {
          timer?.cancel();
          timer = Timer(duration, () => controller.add(event));
        },
        onError: controller.addError,
        onDone: () {
          // The bloc is closing: drop a pending event, nobody will see it.
          timer?.cancel();
          unawaited(controller.close());
        },
      );
    },
    onCancel: () async {
      timer?.cancel();
      await subscription?.cancel();
    },
  );
  return controller.stream;
}

/// For each source event, cancels the previous inner stream and listens
/// to `mapper(event)` instead. Bloc treats a cancelled handler as done, so
/// its later `emit`s are ignored.
Stream<T> _switchMap<S, T>(Stream<S> source, Stream<T> Function(S) mapper) {
  StreamSubscription<S>? outer;
  StreamSubscription<T>? inner;
  var sourceDone = false;
  late final StreamController<T> controller;

  void closeIfFinished() {
    if (sourceDone && inner == null) unawaited(controller.close());
  }

  controller = StreamController<T>(
    onListen: () {
      outer = source.listen(
        (event) {
          unawaited(inner?.cancel());
          late final StreamSubscription<T> current;
          current = mapper(event).listen(
            controller.add,
            onError: controller.addError,
            onDone: () {
              if (identical(inner, current)) {
                inner = null;
                closeIfFinished();
              }
            },
          );
          inner = current;
        },
        onError: controller.addError,
        onDone: () {
          sourceDone = true;
          closeIfFinished();
        },
      );
    },
    onCancel: () async {
      await inner?.cancel();
      await outer?.cancel();
    },
  );
  return controller.stream;
}
