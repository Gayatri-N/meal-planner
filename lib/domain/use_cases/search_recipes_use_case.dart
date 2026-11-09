import 'package:injectable/injectable.dart';

import '../../core/helpers/result.dart';
import '../models/catalog.dart';
import '../models/recipe.dart';
import '../repositories/catalog_repository.dart';
import '../search/recipe_search_index.dart';

/// Searches the catalog. An empty query lists every recipe.
///
/// A lazy singleton so the search index is built once for the app, not
/// once per Recipes screen. Rebuilt only if the catalog itself changes
/// (e.g. after a Firestore update is merged).
@lazySingleton
class SearchRecipesUseCase {
  SearchRecipesUseCase(this._catalog);

  final CatalogRepository _catalog;
  Catalog? _indexedCatalog;
  RecipeSearchIndex? _index;

  Future<Result<List<Recipe>>> call(String query) async {
    final result = await _catalog.load();
    return result.map((catalog) {
      // TODO(release): hide ContentStatus.draft recipes in prod builds
      // (AppConfig.isProd) before the first store release. Drafts are
      // shown everywhere for now while the seed catalog is all drafts.
      return _indexFor(catalog).search(query);
    });
  }

  RecipeSearchIndex _indexFor(Catalog catalog) {
    final index = _index;
    if (index != null && identical(_indexedCatalog, catalog)) return index;
    _indexedCatalog = catalog;
    return _index = RecipeSearchIndex(catalog);
  }
}
