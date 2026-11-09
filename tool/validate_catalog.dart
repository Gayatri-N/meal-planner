// Checks assets/catalog/catalog.json and prints every problem.
//
//   dart run tool/validate_catalog.dart [path]
//
// Exit code 0 = valid, 1 = problems found.
import 'dart:convert';
import 'dart:io';

import 'package:mealplanner/data/catalog/catalog_parser.dart';
import 'package:mealplanner/domain/models/recipe.dart';

void main(List<String> args) {
  final path = args.isEmpty ? 'assets/catalog/catalog.json' : args.first;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Not found: $path');
    exit(1);
  }

  final Object? json;
  try {
    json = jsonDecode(file.readAsStringSync());
  } on FormatException catch (e) {
    stderr.writeln('Invalid JSON in $path: ${e.message}');
    exit(1);
  }

  final result = parseCatalog(json);
  if (!result.isValid) {
    stderr.writeln('${result.issues.length} problem(s) in $path:');
    for (final issue in result.issues) {
      stderr.writeln('  - $issue');
    }
    exit(1);
  }

  final catalog = result.catalog!;
  final byStatus = <ContentStatus, int>{};
  for (final r in catalog.recipes.values) {
    byStatus.update(r.contentStatus, (n) => n + 1, ifAbsent: () => 1);
  }
  stdout.writeln(
    'OK: ${catalog.recipes.length} recipes, '
    '${catalog.ingredients.length} ingredients (version ${catalog.version})',
  );
  for (final status in ContentStatus.values) {
    stdout.writeln('  ${status.name}: ${byStatus[status] ?? 0}');
  }
}
