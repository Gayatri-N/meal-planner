import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../core/helpers/app_exception.dart';
import '../../core/helpers/result.dart';
import '../../core/logger/logger.dart';
import '../../domain/models/catalog.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../catalog/catalog_parser.dart';

/// Loads the bundled `assets/catalog/catalog.json`. Firestore updates
/// (ARCHITECTURE.md §6) will be merged on top of this later.
@LazySingleton(as: CatalogRepository)
class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._bundle, this._logger);

  static const assetPath = 'assets/catalog/catalog.json';

  final AssetBundle _bundle;
  final Logger _logger;
  Future<Result<Catalog>>? _loading;

  /// Caches a successful load. A failure is forgotten once it completes,
  /// so the next call retries. (Cleared here rather than inside [_load]:
  /// if [_load] failed synchronously, clearing there would run before
  /// `??=` stores the future, and the failure would stay cached.)
  @override
  Future<Result<Catalog>> load() {
    final loading = _loading ??= _load();
    return loading.then((result) {
      if (result is Failure<Catalog> && identical(_loading, loading)) {
        _loading = null;
      }
      return result;
    });
  }

  Future<Result<Catalog>> _load() async {
    try {
      // cache: false — this repository keeps the parsed catalog; the
      // bundle need not also keep the raw JSON string for the app's life.
      // TODO(perf): parse in Isolate.run once the catalog passes ~500
      // recipes (see RecipeSearchIndex).
      final raw = await _bundle.loadString(assetPath, cache: false);
      final result = parseCatalog(jsonDecode(raw));
      final catalog = result.catalog;
      if (catalog == null) {
        _logger.error(
          'Invalid catalog: ${result.issues.join('; ')}',
          name: 'catalog',
        );
        return const Failure(
          AppException(
            kind: AppExceptionKind.invalidData,
            message: 'The recipe catalog could not be read.',
          ),
        );
      }
      return Success(catalog);
    } on Object catch (e, s) {
      // TODO(crashlytics): also report through CrashHandler (non-fatal)
      // once Crashlytics is connected in Setup S2.
      _logger.error(
        'Could not load $assetPath',
        error: e,
        stackTrace: s,
        name: 'catalog',
      );
      return Failure(
        AppException(
          kind: AppExceptionKind.invalidData,
          message: 'The recipe catalog could not be read.',
          cause: e,
          stackTrace: s,
        ),
      );
    }
  }
}
