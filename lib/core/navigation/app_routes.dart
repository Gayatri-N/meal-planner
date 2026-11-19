/// Route paths. In `core` so features can navigate without depending on
/// the app layer; the router in `app/navigation` defines the routes.
abstract final class AppRoutes {
  static const home = '/home';
  static const recipes = '/recipes';
  static const track = '/track';

  /// Path segment under [recipes] for one recipe (`:id`).
  static const recipeIdParam = 'id';

  static String recipe(String id) => '$recipes/$id';
}
