import '../../domain/models/catalog.dart';
import '../../domain/models/ingredient.dart';
import '../../domain/models/meal_type.dart';
import '../../domain/models/recipe.dart';
import '../../domain/models/region.dart';

/// Result of reading `catalog.json`. [catalog] is null when [issues]
/// is not empty: a catalog with problems is never handed to the app.
class CatalogParseResult {
  const CatalogParseResult._(this.catalog, this.issues);

  final Catalog? catalog;

  /// Human-readable problems, each prefixed with a JSON path.
  final List<String> issues;

  bool get isValid => issues.isEmpty;
}

final _idPattern = RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$');
final _devanagari = RegExp(r'[ऀ-ॿ]');

/// Parses and validates the catalog in one pass, collecting every
/// problem instead of stopping at the first.
CatalogParseResult parseCatalog(Object? json) {
  final p = _Parser();
  final catalog = p.catalog(json);
  return CatalogParseResult._(p.issues.isEmpty ? catalog : null, p.issues);
}

class _Parser {
  final issues = <String>[];

  void _issue(String path, String message) => issues.add('$path: $message');

  Catalog? catalog(Object? json) {
    if (json is! Map<String, Object?>) {
      _issue(r'$', 'must be an object');
      return null;
    }
    final version = _int(json, 'catalogVersion', r'$', min: 1) ?? 0;

    final ingredients = <Ingredient>[];
    final ingredientJson = _list(json, 'ingredients', r'$');
    for (var i = 0; i < ingredientJson.length; i++) {
      final ing = _ingredient(ingredientJson[i], '\$.ingredients[$i]');
      if (ing != null) ingredients.add(ing);
    }
    _checkUnique(ingredients.map((e) => e.id), r'$.ingredients');
    final byId = {for (final i in ingredients) i.id: i};

    final recipes = <Recipe>[];
    final recipeJson = _list(json, 'recipes', r'$');
    for (var i = 0; i < recipeJson.length; i++) {
      final r = _recipe(recipeJson[i], '\$.recipes[$i]', byId);
      if (r != null) recipes.add(r);
    }
    _checkUnique(recipes.map((e) => e.id), r'$.recipes');

    return Catalog(
      version: version,
      ingredients: ingredients,
      recipes: recipes,
    );
  }

  Ingredient? _ingredient(Object? json, String path) {
    if (json is! Map<String, Object?>) {
      _issue(path, 'must be an object');
      return null;
    }
    final id = _id(json, path);
    final nameEn = _str(json, 'nameEn', path);
    final nameMr = _marathi(json, 'nameMr', path);
    final categoryName = _str(json, 'category', path);
    final category = IngredientCategory.tryParse(categoryName);
    if (categoryName.isNotEmpty && category == null) {
      _issue('$path.category', 'unknown category "$categoryName"');
    }
    final units = _strList(json, 'commonUnits', path);
    if (units.isEmpty) _issue('$path.commonUnits', 'needs at least one unit');

    return Ingredient(
      id: id,
      nameEn: nameEn,
      nameMr: nameMr,
      aliases: _strList(json, 'aliases', path, required: false),
      category: category ?? IngredientCategory.staples,
      commonUnits: units,
    );
  }

  Recipe? _recipe(
    Object? json,
    String path,
    Map<String, Ingredient> ingredients,
  ) {
    if (json is! Map<String, Object?>) {
      _issue(path, 'must be an object');
      return null;
    }
    final id = _id(json, path);

    final mealTypes = <MealType>[];
    for (final name in _strList(json, 'mealTypes', path)) {
      final t = MealType.tryParse(name);
      t == null
          ? _issue('$path.mealTypes', 'unknown meal type "$name"')
          : mealTypes.add(t);
    }
    if (mealTypes.isEmpty) _issue('$path.mealTypes', 'needs at least one');

    final dietName = _str(json, 'diet', path);
    final diet = Diet.tryParse(dietName);
    if (dietName.isNotEmpty && diet == null) {
      _issue('$path.diet', 'unknown diet "$dietName"');
    }

    final statusName = _str(json, 'contentStatus', path);
    final status = ContentStatus.tryParse(statusName);
    if (statusName.isNotEmpty && status == null) {
      _issue('$path.contentStatus', 'unknown status "$statusName"');
    }

    final regionIds = _strList(json, 'regionIds', path);
    for (final r in regionIds) {
      if (!Regions.all.contains(r)) {
        _issue('$path.regionIds', 'unknown region "$r"');
      }
    }
    if (regionIds.isEmpty) _issue('$path.regionIds', 'needs at least one');

    final lines = <RecipeIngredientLine>[];
    final linesJson = _list(json, 'ingredientLines', path);
    if (linesJson.isEmpty) {
      _issue('$path.ingredientLines', 'needs at least one');
    }
    for (var i = 0; i < linesJson.length; i++) {
      final line = _line(
        linesJson[i],
        '$path.ingredientLines[$i]',
        ingredients,
      );
      if (line != null) lines.add(line);
    }

    final steps = <RecipeStep>[];
    final stepsJson = _list(json, 'steps', path);
    if (stepsJson.isEmpty) _issue('$path.steps', 'needs at least one');
    for (var i = 0; i < stepsJson.length; i++) {
      final s = stepsJson[i];
      final sp = '$path.steps[$i]';
      if (s is! Map<String, Object?>) {
        _issue(sp, 'must be an object');
        continue;
      }
      steps.add(RecipeStep(en: _str(s, 'en', sp), mr: _marathi(s, 'mr', sp)));
    }

    final image = json['imageAsset'];
    if (image != null && image is! String) {
      _issue('$path.imageAsset', 'must be a string');
    }

    return Recipe(
      id: id,
      nameEn: _str(json, 'nameEn', path),
      nameMr: _marathi(json, 'nameMr', path),
      aliases: _strList(json, 'aliases', path, required: false),
      mealTypes: mealTypes,
      diet: diet ?? Diet.veg,
      baseServings: _int(json, 'baseServings', path, min: 1) ?? 1,
      prepMinutes: _int(json, 'prepMinutes', path, min: 0) ?? 0,
      cookMinutes: _int(json, 'cookMinutes', path, min: 0) ?? 0,
      regionIds: regionIds,
      seasonTags: _strList(json, 'seasonTags', path, required: false),
      festivalTags: _strList(json, 'festivalTags', path, required: false),
      occasionTags: _strList(json, 'occasionTags', path, required: false),
      ingredientLines: lines,
      steps: steps,
      contentStatus: status ?? ContentStatus.draft,
      imageAsset: image is String ? image : null,
    );
  }

  RecipeIngredientLine? _line(
    Object? json,
    String path,
    Map<String, Ingredient> ingredients,
  ) {
    if (json is! Map<String, Object?>) {
      _issue(path, 'must be an object');
      return null;
    }
    final ingredientId = _str(json, 'ingredientId', path);
    final unit = _str(json, 'unit', path);
    final rawQty = json['qty'];

    double? qty;
    if (unit == toTasteUnit) {
      if (rawQty != null) _issue('$path.qty', 'must be omitted for to_taste');
    } else if (rawQty is num && rawQty > 0) {
      qty = rawQty.toDouble();
    } else {
      _issue('$path.qty', 'must be a number > 0');
    }

    final ingredient = ingredients[ingredientId];
    if (ingredientId.isNotEmpty && ingredient == null) {
      _issue('$path.ingredientId', 'unknown ingredient "$ingredientId"');
    } else if (ingredient != null &&
        unit.isNotEmpty &&
        unit != toTasteUnit &&
        !ingredient.commonUnits.contains(unit)) {
      _issue(
        '$path.unit',
        '"$unit" is not in $ingredientId.commonUnits '
            '${ingredient.commonUnits}',
      );
    }

    final optional = json['optional'];
    if (optional != null && optional is! bool) {
      _issue('$path.optional', 'must be true or false');
    }

    return RecipeIngredientLine(
      ingredientId: ingredientId,
      qty: qty,
      unit: unit,
      optional: optional == true,
    );
  }

  // --- field helpers ------------------------------------------------------

  String _id(Map<String, Object?> json, String path) {
    final id = _str(json, 'id', path);
    if (id.isNotEmpty && !_idPattern.hasMatch(id)) {
      _issue('$path.id', '"$id" must be lower_snake_case');
    }
    return id;
  }

  String _str(Map<String, Object?> json, String key, String path) {
    final v = json[key];
    if (v is String && v.trim().isNotEmpty) return v;
    _issue('$path.$key', 'must be a non-empty string');
    return '';
  }

  String _marathi(Map<String, Object?> json, String key, String path) {
    final v = _str(json, key, path);
    if (v.isNotEmpty && !_devanagari.hasMatch(v)) {
      _issue('$path.$key', 'must be written in Devanagari');
    }
    return v;
  }

  int? _int(
    Map<String, Object?> json,
    String key,
    String path, {
    required int min,
  }) {
    final v = json[key];
    if (v is int && v >= min) return v;
    _issue('$path.$key', 'must be an integer >= $min');
    return null;
  }

  List<Object?> _list(Map<String, Object?> json, String key, String path) {
    final v = json[key];
    if (v is List<Object?>) return v;
    _issue('$path.$key', 'must be a list');
    return const [];
  }

  List<String> _strList(
    Map<String, Object?> json,
    String key,
    String path, {
    bool required = true,
  }) {
    final v = json[key];
    if (v == null && !required) return const [];
    if (v is! List<Object?> || v.any((e) => e is! String)) {
      _issue('$path.$key', 'must be a list of strings');
      return const [];
    }
    return v.cast<String>();
  }

  void _checkUnique(Iterable<String> ids, String path) {
    final seen = <String>{};
    for (final id in ids) {
      if (id.isNotEmpty && !seen.add(id)) _issue(path, 'duplicate id "$id"');
    }
  }
}
