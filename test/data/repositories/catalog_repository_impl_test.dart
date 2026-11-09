import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/core/helpers/result.dart';
import 'package:mealplanner/core/logger/logger.dart';
import 'package:mealplanner/data/repositories/catalog_repository_impl.dart';

/// Fails the first load (synchronously or asynchronously), then serves
/// the real catalog.
class _FlakyBundle extends CachingAssetBundle {
  _FlakyBundle({required this.failSynchronously});

  final bool failSynchronously;
  int calls = 0;

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    if (calls++ == 0) {
      if (failSynchronously) throw StateError('disk error');
      return Future.error(StateError('disk error'));
    }
    return Future.value(File(key).readAsStringSync());
  }

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

void main() {
  group('CatalogRepositoryImpl', () {
    for (final sync in [true, false]) {
      test(
        'retries after a ${sync ? 'synchronous' : 'async'} failure',
        () async {
          final bundle = _FlakyBundle(failSynchronously: sync);
          final repo = CatalogRepositoryImpl(bundle, Logger());

          expect(await repo.load(), isA<Failure<Object?>>());
          expect(await repo.load(), isA<Success<Object?>>());
          expect(bundle.calls, 2);
        },
      );
    }

    test('caches a successful load', () async {
      final bundle = _FlakyBundle(failSynchronously: false)..calls = 1;
      final repo = CatalogRepositoryImpl(bundle, Logger());

      await repo.load();
      await repo.load();
      expect(bundle.calls, 2); // one real load after the skipped failure
    });
  });
}
