import '../models/catalog.dart';
import '../models/recipe.dart';

/// In-memory recipe search over names, aliases and ingredient names
/// (ARCHITECTURE.md §6). Tolerates case, hyphens, spacing, and small
/// typos, so `Kanda-Poha`, `kandapoha` and `pithale` all match.
///
/// Every searchable form of every name is computed once here, so a
/// keystroke only compares strings. Past ~500 recipes, add a trigram
/// index to pick candidates and build it off the UI isolate.
class RecipeSearchIndex {
  RecipeSearchIndex(Catalog catalog)
    : _entries = [
        for (final recipe in catalog.recipes.values)
          _Entry(
            recipe: recipe,
            names: _terms([recipe.nameEn, recipe.nameMr, ...recipe.aliases]),
            ingredientTerms: _terms([
              for (final line in recipe.ingredientLines)
                if (catalog.ingredients[line.ingredientId] case final ing?) ...[
                  ing.nameEn,
                  ing.nameMr,
                  ...ing.aliases,
                ],
            ]),
          ),
      ]..sort((a, b) => a.recipe.nameEn.compareTo(b.recipe.nameEn));

  /// Sorted by English name, so ties and the empty query need no sort.
  final List<_Entry> _entries;

  /// Recipes matching [query], best first. An empty query returns
  /// every recipe sorted by English name.
  List<Recipe> search(String query) {
    final q = _Term(normalize(query));
    if (q.full.isEmpty) return [for (final e in _entries) e.recipe];

    // (recipe, score, position in English-name order)
    final scored = <(Recipe, int, int)>[];
    for (final (i, entry) in _entries.indexed) {
      final score = entry.score(q);
      if (score > 0) scored.add((entry.recipe, score, i));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      return byScore != 0 ? byScore : a.$3.compareTo(b.$3);
    });
    return [for (final (recipe, _, _) in scored) recipe];
  }

  static final _punctuation = RegExp(r'[-_.,/()!?]+');
  static final _whitespace = RegExp(r'\s+');

  /// Zero-width non-joiner/joiner (U+200C/U+200D). Marathi text uses
  /// them for some conjunct shapes (eyelash ra), but keyboards often omit
  /// them, so `र्‍या` and `र्या` must match.
  static final _zeroWidthJoiners = RegExp('[‌‍]');

  /// Lowercase, hyphens/punctuation to spaces, collapsed whitespace,
  /// zero-width joiners removed. Devanagari letters and vowel signs are
  /// kept as they are.
  static String normalize(String input) => input
      .toLowerCase()
      .replaceAll(_zeroWidthJoiners, '')
      .replaceAll(_punctuation, ' ')
      .replaceAll(_whitespace, ' ')
      .trim();

  static List<_Term> _terms(Iterable<String> raw) =>
      {for (final s in raw) normalize(s)}
          .where((s) => s.isNotEmpty)
          .map(_Term.new)
          .toList(growable: false);
}

/// A normalized string with its precomputed search forms.
class _Term {
  _Term(this.full)
    : compact = full.replaceAll(' ', ''),
      words = full.split(' ');

  final String full;
  final String compact;
  final List<String> words;
}

class _Entry {
  _Entry({
    required this.recipe,
    required this.names,
    required this.ingredientTerms,
  });

  final Recipe recipe;
  final List<_Term> names;
  final List<_Term> ingredientTerms;

  /// Shortest query matched anywhere inside a name, or against
  /// ingredients. Shorter queries match name/word starts only, so `a`
  /// does not return every recipe containing an "a".
  static const _minInfixLength = 3;

  int score(_Term q) {
    var best = 0;
    for (final name in names) {
      if (name.full == q.full || name.compact == q.compact) return 100;
      if (name.full.startsWith(q.full) || name.compact.startsWith(q.compact)) {
        if (best < 80) best = 80;
      } else if (name.words.any((w) => w.startsWith(q.full))) {
        if (best < 70) best = 70;
      } else if (q.compact.length >= _minInfixLength &&
          name.compact.contains(q.compact)) {
        if (best < 60) best = 60;
      } else if (best < 50 &&
          (_isCloseTypo(q.compact, name.compact) ||
              name.words.any((w) => _isCloseTypo(q.full, w)))) {
        best = 50;
      }
    }
    if (best > 0 || q.compact.length < _minInfixLength) return best;

    for (final term in ingredientTerms) {
      // Whole term or any word: "green chil" and "chil" both find
      // "green chilli".
      if (term.full.startsWith(q.full) ||
          term.compact.startsWith(q.compact) ||
          term.words.any((w) => w.startsWith(q.full))) {
        return 30;
      }
    }
    return 0;
  }

  /// One edit for short words, two for longer ones. Needs 4+ characters
  /// so short queries do not match everything.
  static bool _isCloseTypo(String query, String target) {
    if (query.length < 4) return false;
    final allowed = query.length <= 6 ? 1 : 2;
    if ((query.length - target.length).abs() > allowed) return false;
    return _editDistance(query, target, allowed) <= allowed;
  }

  /// Levenshtein distance with two reused rows, stopping early once
  /// every cell in a row exceeds [limit].
  static int _editDistance(String a, String b, int limit) {
    var prev = List<int>.generate(b.length + 1, (i) => i);
    var curr = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      var rowMin = i;
      final ca = a.codeUnitAt(i - 1);
      for (var j = 1; j <= b.length; j++) {
        final substitute = prev[j - 1] + (ca == b.codeUnitAt(j - 1) ? 0 : 1);
        final delete = prev[j] + 1;
        final insert = curr[j - 1] + 1;
        var v = substitute < delete ? substitute : delete;
        if (insert < v) v = insert;
        curr[j] = v;
        if (v < rowMin) rowMin = v;
      }
      if (rowMin > limit) return limit + 1;
      final swap = prev;
      prev = curr;
      curr = swap;
    }
    return prev[b.length];
  }
}
