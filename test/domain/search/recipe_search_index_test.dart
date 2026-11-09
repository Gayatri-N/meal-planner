import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/data/catalog/catalog_parser.dart';
import 'package:mealplanner/domain/search/recipe_search_index.dart';

void main() {
  late RecipeSearchIndex index;

  setUpAll(() {
    final json = jsonDecode(
      File('assets/catalog/catalog.json').readAsStringSync(),
    );
    index = RecipeSearchIndex(parseCatalog(json).catalog!);
  });

  String? top(String query) {
    final results = index.search(query);
    return results.isEmpty ? null : results.first.id;
  }

  group('RecipeSearchIndex', () {
    const cases = {
      // English, any case
      'Kanda Poha': 'kanda_poha',
      'POHA': 'kanda_poha',
      // hyphen vs space vs none
      'kanda-poha': 'kanda_poha',
      'kandapoha': 'kanda_poha',
      '  kanda   poha ': 'kanda_poha',
      // Marathi
      'कांदे पोहे': 'kanda_poha',
      'पिठलं': 'pithla',
      'पिठले': 'pithla',
      'वरण': 'varan',
      // transliteration variants (aliases)
      'pithale': 'pithla',
      'pitla': 'pithla',
      'waran': 'varan',
      // prefix while typing
      'pith': 'pithla',
      // small typo
      'pithlla': 'pithla',
      'kanda pohw': 'kanda_poha',
      // ingredient
      'besan': 'pithla',
      'तूर डाळ': 'varan',
    };

    for (final MapEntry(key: query, value: expected) in cases.entries) {
      test('"$query" finds $expected first', () {
        expect(top(query), expected);
      });
    }

    test('empty query lists every recipe by English name', () {
      expect(index.search('').map((r) => r.id), [
        'kanda_poha',
        'pithla',
        'varan',
      ]);
    });

    test('unrelated query finds nothing', () {
      expect(index.search('pizza'), isEmpty);
    });

    test('short queries do not fuzzy-match everything', () {
      expect(index.search('xyz'), isEmpty);
    });

    test('1–2 letters match name starts only, not the middle', () {
      // 'nd' is inside "kanda" but starts no word.
      expect(index.search('nd'), isEmpty);
      // 'a' starts no recipe word, and is too short for ingredients
      // ("asafoetida" in Varan).
      expect(index.search('a'), isEmpty);
      // Word starts still work from one letter (Varan via "plain dal").
      expect(index.search('p').map((r) => r.id), [
        'kanda_poha',
        'pithla',
        'varan',
      ]);
    });

    test('3+ letters match inside names', () {
      expect(index.search('and').map((r) => r.id), ['kanda_poha']);
    });
  });
}
