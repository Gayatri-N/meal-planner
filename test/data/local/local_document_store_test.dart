import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/core/logger/logger.dart';
import 'package:mealplanner/data/local/local_document_store.dart';

import '../../helpers/fakes.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('mp_store_'));
  tearDown(() => dir.deleteSync(recursive: true));

  LocalDocumentStore store() =>
      LocalDocumentStore(directory: () async => dir, logger: Logger());

  group('LocalDocumentStore', () {
    test('a missing document reads as null', () async {
      expect(await store().get('days', '2026-11-09'), isNull);
    });

    test('dotted paths create nested fields; deleteField removes', () async {
      final s = store();
      await s.update('days', 'd1', {
        'date': 'd1',
        'slots.lunch.status': 'planned',
        'slots.lunch.items.a': {'order': 0},
      });
      await s.update('days', 'd1', {'slots.lunch.status': 'eaten'});

      expect(await s.get('days', 'd1'), {
        'date': 'd1',
        'slots': {
          'lunch': {
            'status': 'eaten',
            'items': {
              'a': {'order': 0},
            },
          },
        },
      });

      await s.update('days', 'd1', {'slots.lunch': deleteField});
      expect(await s.get('days', 'd1'), {
        'date': 'd1',
        'slots': <String, Object?>{},
      });
    });

    test(
      'a dotted path replaces that field entirely (like Firestore update)',
      () async {
        final s = store();
        await s.update('days', 'd1', {
          'slots.lunch': {
            'items': {'old': 1},
          },
        });
        await s.update('days', 'd1', {
          'slots.lunch': {
            'items': {'new': 2},
          },
        });

        expect((await s.get('days', 'd1'))?['slots'], {
          'lunch': {
            'items': {'new': 2},
          },
        });
      },
    );

    test('data survives a restart (new store, same file)', () async {
      await store().update('days', 'd1', {'slots.dinner.status': 'cooked'});
      // Give the queued file write a moment.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final reopened = await store().get('days', 'd1');
      expect(reopened, {
        'slots': {
          'dinner': {'status': 'cooked'},
        },
      });
    });

    test('many quick writes all reach the file, in order', () async {
      final s = store();
      await Future.wait([
        for (var i = 0; i < 20; i++) s.update('days', 'd1', {'n.$i': i}),
      ]);
      final saved = jsonDecode(
        File('${dir.path}/local_store.json').readAsStringSync(),
      ) as Map<String, Object?>;
      expect(((saved['days']! as Map)['d1']! as Map)['n'], {
        for (var i = 0; i < 20; i++) '$i': i,
      });
    });

    test('watch emits now and after each change', () async {
      final s = store();
      final seen = <Object?>[];
      final sub = s.watch('days', 'd1').listen(seen.add);
      await Future<void>.delayed(Duration.zero);

      await s.update('days', 'd1', {'a': 1});
      await s.update('days', 'd1', {'a': 2});
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(seen, [
        null,
        {'a': 1},
        {'a': 2},
      ]);
    });

    test('returned documents are copies', () async {
      final s = store();
      await s.update('days', 'd1', {'a': 1});
      (await s.get('days', 'd1'))!['a'] = 99;
      expect(await s.get('days', 'd1'), {'a': 1});
    });

    test(
      'an unreadable file is set aside and the store starts empty',
      () async {
        File('${dir.path}/local_store.json').writeAsStringSync('{not json');

        expect(await store().get('days', 'd1'), isNull);
        expect(
          dir.listSync().map((f) => f.path).any((p) => p.contains('.corrupt-')),
          isTrue,
        );
      },
    );

    test('all() lists every document, for migration to Firestore', () async {
      final s = tempStore(dir: dir);
      await s.update('days', '2026-11-08', {'date': '2026-11-08'});
      await s.update('days', '2026-11-09', {'date': '2026-11-09'});

      expect((await s.all('days')).keys, ['2026-11-08', '2026-11-09']);
    });
  });
}
