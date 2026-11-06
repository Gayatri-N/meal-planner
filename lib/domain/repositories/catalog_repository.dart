import '../../core/helpers/result.dart';
import '../models/catalog.dart';

/// Read-only access to the on-device recipe catalog.
abstract interface class CatalogRepository {
  /// Loads the catalog once and returns the cached copy afterwards.
  Future<Result<Catalog>> load();
}
