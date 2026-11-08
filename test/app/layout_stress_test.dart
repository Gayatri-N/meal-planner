import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/app/app.dart';
import 'package:mealplanner/app/di/di.dart';
import 'package:mealplanner/core/env/app_config.dart';
import 'package:mealplanner/data/repositories/catalog_repository_impl.dart';

import '../helpers/test_app.dart';

const longEn =
    'Grandmother’s Special Kolhapuri Kanda Poha with Extra Peanuts and Lemon';
const longMr =
    'आजीच्या खास पद्धतीचे कोल्हापुरी कांदे पोहे शेंगदाणे आणि लिंबासह';

/// The real catalog with one recipe and one ingredient given very long
/// names, so layout problems show up in tests instead of on phones.
String stressCatalog() {
  final json = jsonDecode(
    File(CatalogRepositoryImpl.assetPath).readAsStringSync(),
  ) as Map<String, Object?>;
  final recipes = (json['recipes']! as List<Object?>)
      .cast<Map<String, Object?>>();
  recipes.first
    ..['nameEn'] = longEn
    ..['nameMr'] = longMr;
  final ingredients = (json['ingredients']! as List<Object?>)
      .cast<Map<String, Object?>>();
  ingredients.first
    ..['nameEn'] = 'Thick flattened rice from the local mill (jada pohe)'
    ..['nameMr'] = 'गिरणीतले जाड पोहे (स्थानिक दुकानातून आणलेले)';
  return jsonEncode(json);
}

void main() {
  // Smallest common phone (iPhone SE 1st gen), font size at 200%.
  const phone = Size(320, 568);
  const textScale = 2.0;

  setUp(() {
    configureTestDependencies(
      assets: {CatalogRepositoryImpl.assetPath: stressCatalog()},
    );
  });
  tearDown(() => getIt.reset());

  for (final locale in ['en', 'mr']) {
    testWidgets('no overflow at 2× text on a small phone ($locale)', (
      tester,
    ) async {
      tester.view
        ..physicalSize = phone * 3
        ..devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MealPlannerApp(config: getIt<AppConfig>(), locale: Locale(locale)),
      );
      await tester.pumpAndSettle();

      // Recipes tab (second destination).
      await tester.tap(find.byIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Open the long-named recipe and scroll to the end.
      await tester.tap(find.text(locale == 'mr' ? longMr : longEn));
      await tester.pumpAndSettle();
      await tester.fling(find.byType(ListView), const Offset(0, -3000), 3000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
