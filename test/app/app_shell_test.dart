import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/app/app.dart';
import 'package:mealplanner/app/di/di.dart';
import 'package:mealplanner/core/env/app_config.dart';
import 'package:mealplanner/core/env/app_environment.dart';

void main() {
  setUp(() => configureDependencies(AppEnvironment.dev));
  tearDown(() => getIt.reset());

  group('MealPlannerApp', () {
    testWidgets('opens on Home and switches tabs', (tester) async {
      await tester.pumpWidget(
        MealPlannerApp(config: getIt<AppConfig>(), locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.text('What should we cook today?'), findsOneWidget);

      await tester.tap(find.text('Recipes').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Maharashtrian recipes will appear here.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Track').last);
      await tester.pumpAndSettle();
      expect(
        find.text('A record of what you ate will appear here.'),
        findsOneWidget,
      );
    });

    testWidgets('shows Marathi UI strings', (tester) async {
      await tester.pumpWidget(
        MealPlannerApp(config: getIt<AppConfig>(), locale: const Locale('mr')),
      );
      await tester.pumpAndSettle();

      expect(find.text('आज काय बनवायचं?'), findsOneWidget);
      expect(find.text('पाककृती'), findsOneWidget);
    });
  });
}
