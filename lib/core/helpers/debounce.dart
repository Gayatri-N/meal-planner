import 'dart:async';

/// BLoC event transformer: waits until no new event has arrived for
/// [duration], then handles only the latest one. Use for search-as-you-type.
///
/// Signature matches `EventTransformer<E>` from package:bloc, so it can be
/// passed as `on<E>(handler, transformer: debounce(...))`.
Stream<E> Function(Stream<E> events, Stream<E> Function(E) mapper) debounce<E>(
  Duration duration,
) =>
    (events, mapper) => _debounced(events, duration).asyncExpand(mapper);

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
