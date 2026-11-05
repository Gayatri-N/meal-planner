import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/data/catalog/catalog_parser.dart';

/// Guards the bundled catalog: CI fails if content has a problem.
void main() {
  test('bundled catalog.json is valid', () {
    final json = jsonDecode(
      File('assets/catalog/catalog.json').readAsStringSync(),
    );
    final result = parseCatalog(json);

    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
    expect(result.catalog!.recipes, isNotEmpty);
  });
}
