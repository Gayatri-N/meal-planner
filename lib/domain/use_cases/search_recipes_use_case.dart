import 'package:injectable/injectable.dart';

import '../../core/helpers/result.dart';
import '../models/recipe.dart';
import '../repositories/catalog_repository.dart';
import '../search/recipe_search_index.dart';

/// Searches the catalog. An empty query lists every recipe.
@injectable
class SearchRecipesUseCase {
  SearchRecipesUseCase(this._catalog);

  final CatalogRepository _catalog;
  RecipeSearchIndex? _index;

  Future<Result<List<Recipe>>> call(String query) async {
    final result = await _catalog.load();
    return result.map((catalog) {
      // TODO(release): hide ContentStatus.draft recipes in prod builds
      // (AppConfig.isProd) before the first store release. Drafts are
      // shown everywhere for now while the seed catalog is all drafts.
      final index = _index ??= RecipeSearchIndex(catalog);
      return index.search(query);
    });
  }
}
