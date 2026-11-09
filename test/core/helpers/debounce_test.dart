import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/core/helpers/debounce.dart';

void main() {
  group('debounceRestartable', () {
    const wait = Duration(milliseconds: 100);
    const work = Duration(milliseconds: 300);

    /// Runs [events] through the transformer with a mapper that takes
    /// [work] per event, and returns what came out.
    List<String> run(void Function(StreamController<String>, FakeAsync) feed) {
      final out = <String>[];
      fakeAsync((async) {
        final input = StreamController<String>();
        debounceRestartable<String>(wait)(
          input.stream,
          (e) => Stream.fromFuture(Future.delayed(work, () => e)),
        ).listen(out.add);
        feed(input, async);
        async.elapse(const Duration(seconds: 5));
      });
      return out;
    }

    test('fast typing handles only the last value', () {
      final out = run((input, async) {
        for (final q in ['p', 'po', 'poh', 'poha']) {
          input.add(q);
          async.elapse(const Duration(milliseconds: 30));
        }
      });
      expect(out, ['poha']);
    });

    test('a newer value cancels a slow search still running', () {
      final out = run((input, async) {
        input.add('po');
        async.elapse(wait + const Duration(milliseconds: 50)); // 'po' running
        input.add('poha');
        async.elapse(wait + const Duration(milliseconds: 50)); // cancels 'po'
        input.add('pohe');
      });
      expect(out, ['pohe']);
    });

    test('values separated by more than the work time all come through', () {
      final out = run((input, async) {
        input.add('poha');
        async.elapse(wait + work + const Duration(milliseconds: 50));
        input.add('pithla');
      });
      expect(out, ['poha', 'pithla']);
    });
  });
}
