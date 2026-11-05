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

  @override
  Future<Result<Catalog>> load() => _loading ??= _load();

  Future<Result<Catalog>> _load() async {
    try {
      final raw = await _bundle.loadString(assetPath);
      final result = parseCatalog(jsonDecode(raw));
      final catalog = result.catalog;
      if (catalog == null) {
        _logger.error('Invalid catalog: ${result.issues.join('; ')}');
        _loading = null;
        return const Failure(
          AppException(
            kind: AppExceptionKind.invalidData,
            message: 'The recipe catalog could not be read.',
          ),
        );
      }
      return Success(catalog);
    } on Object catch (e, s) {
      _loading = null;
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
