import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/app/app.dart';
import 'package:mealplanner/app/di/di.dart';
import 'package:mealplanner/core/env/app_config.dart';
import 'package:mealplanner/features/recipes/bloc/recipes_bloc.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(configureTestDependencies);
  tearDown(() => getIt.reset());

  Future<void> pumpApp(WidgetTester tester, String locale) async {
    await tester.pumpWidget(
      MealPlannerApp(config: getIt<AppConfig>(), locale: Locale(locale)),
    );
    await tester.pumpAndSettle();
  }

  group('MealPlannerApp', () {
    testWidgets('opens on Home and switches tabs', (tester) async {
      await pumpApp(tester, 'en');
      expect(find.text('What should we cook today?'), findsOneWidget);

      await tester.tap(find.text('Recipes').last);
      await tester.pumpAndSettle();
      expect(find.text('Kanda Poha'), findsOneWidget);

      await tester.tap(find.text('Track').last);
      await tester.pumpAndSettle();
      expect(
        find.text('A record of what you ate will appear here.'),
        findsOneWidget,
      );
    });

    testWidgets('searches recipes and scales servings', (tester) async {
      await pumpApp(tester, 'en');
      await tester.tap(find.text('Recipes').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'pithale');
      await tester.pump(RecipesBloc.searchDebounce * 2);
      await tester.pumpAndSettle();
      expect(find.text('Pithla'), findsOneWidget);
      expect(find.text('Kanda Poha'), findsNothing);

      await tester.tap(find.text('Pithla'));
      await tester.pumpAndSettle();
      expect(find.text('Ingredients'), findsOneWidget);
      expect(find.text('60 g'), findsOneWidget); // base: 2 servings

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('90 g'), findsOneWidget); // 3 servings
      await tester.scrollUntilVisible(find.text('to taste'), 200);
      expect(find.text('to taste'), findsOneWidget);
    });

    testWidgets('shows Marathi UI strings and recipe names', (tester) async {
      await pumpApp(tester, 'mr');
      expect(find.text('आज काय बनवायचं?'), findsOneWidget);

      await tester.tap(find.text('पाककृती').last);
      await tester.pumpAndSettle();
      expect(find.text('कांदे पोहे'), findsOneWidget);
    });
  });
}
