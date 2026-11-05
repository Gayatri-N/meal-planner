import '../models/catalog.dart';
import '../models/recipe.dart';

/// In-memory recipe search over names, aliases and ingredient names
/// (ARCHITECTURE.md §6). Tolerates case, hyphens, spacing, and small
/// typos, so `Kanda-Poha`, `kandapoha` and `pithale` all match.
class RecipeSearchIndex {
  RecipeSearchIndex(Catalog catalog)
    : _entries = [
        for (final recipe in catalog.recipes.values)
          _Entry(
            recipe: recipe,
            names: {
              recipe.nameEn,
              recipe.nameMr,
              ...recipe.aliases,
            }.map(normalize).where((s) => s.isNotEmpty).toSet(),
            ingredientTerms: {
              for (final line in recipe.ingredientLines)
                if (catalog.ingredients[line.ingredientId] case final ing?) ...[
                  ing.nameEn,
                  ing.nameMr,
                  ...ing.aliases,
                ],
            }.map(normalize).where((s) => s.isNotEmpty).toSet(),
          ),
      ];

  final List<_Entry> _entries;

  /// Recipes matching [query], best first. An empty query returns
  /// every recipe sorted by English name.
  List<Recipe> search(String query) {
    final q = normalize(query);
    if (q.isEmpty) {
      return _entries.map((e) => e.recipe).toList()
        ..sort((a, b) => a.nameEn.compareTo(b.nameEn));
    }

    final scored = <(Recipe, int)>[];
    for (final entry in _entries) {
      final score = entry.score(q);
      if (score > 0) scored.add((entry.recipe, score));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      return byScore != 0 ? byScore : a.$1.nameEn.compareTo(b.$1.nameEn);
    });
    return [for (final (recipe, _) in scored) recipe];
  }

  /// Lowercase, hyphens/punctuation to spaces, collapsed whitespace.
  /// Devanagari letters and vowel signs are kept as they are.
  static String normalize(String input) => input
      .toLowerCase()
      .replaceAll(RegExp(r'[-_.,/()!?]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _Entry {
  _Entry({
    required this.recipe,
    required this.names,
    required this.ingredientTerms,
  });

  final Recipe recipe;
  final Set<String> names;
  final Set<String> ingredientTerms;

  int score(String q) {
    final compactQ = _compact(q);
    var best = 0;

    for (final name in names) {
      final compact = _compact(name);
      if (name == q || compact == compactQ) return 100;
      if (name.startsWith(q) || compact.startsWith(compactQ)) {
        best = _max(best, 80);
      } else if (_words(name).any((w) => w.startsWith(q))) {
        best = _max(best, 70);
      } else if (compact.contains(compactQ)) {
        best = _max(best, 60);
      } else if (_isCloseTypo(compactQ, compact) ||
          _words(name).any((w) => _isCloseTypo(q, w))) {
        best = _max(best, 50);
      }
    }
    if (best > 0) return best;

    for (final term in ingredientTerms) {
      if (term == q || _words(term).any((w) => w.startsWith(q))) {
        best = _max(best, 30);
      }
    }
    return best;
  }

  static String _compact(String s) => s.replaceAll(' ', '');
  static Iterable<String> _words(String s) => s.split(' ');
  static int _max(int a, int b) => a > b ? a : b;

  /// One edit for short words, two for longer ones. Needs 4+ characters
  /// so short queries do not match everything.
  static bool _isCloseTypo(String query, String target) {
    if (query.length < 4) return false;
    final allowed = query.length <= 6 ? 1 : 2;
    if ((query.length - target.length).abs() > allowed) return false;
    return _editDistance(query, target, allowed) <= allowed;
  }

  /// Levenshtein distance, stopping early once it exceeds [limit].
  static int _editDistance(String a, String b, int limit) {
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final curr = List<int>.filled(b.length + 1, 0)..[0] = i;
      var rowMin = curr[0];
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        curr[j] = [
          prev[j] + 1,
          curr[j - 1] + 1,
          prev[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
        if (curr[j] < rowMin) rowMin = curr[j];
      }
      if (rowMin > limit) return limit + 1;
      prev = curr;
    }
    return prev[b.length];
  }
}
