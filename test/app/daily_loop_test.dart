import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/app/app.dart';
import 'package:mealplanner/app/di/di.dart';
import 'package:mealplanner/core/env/app_config.dart';

import '../helpers/test_app.dart';

/// MVP exit loop on one screen flow: find a recipe → put it on today →
/// mark it cooked → mark it eaten (PRD Loop A, minus week and grocery).
void main() {
  setUp(configureTestDependencies);
  tearDown(() => getIt.reset());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(400, 900) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MealPlannerApp(config: getIt<AppConfig>(), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> addToToday(
    WidgetTester tester,
    String recipe,
    String meal,
  ) async {
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text(recipe));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to today'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, meal));
    await tester.pumpAndSettle();
  }

  Future<void> goHome(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
  }

  testWidgets('plan, cook and eat a meal from the recipe screen', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Nothing planned yet'), findsNWidgets(3));

    await addToToday(tester, 'Pithla', 'Lunch');
    expect(find.text('Added to Lunch'), findsOneWidget);

    // "View" on the snackbar goes Home, where lunch now shows Pithla.
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.text('Pithla'), findsOneWidget);
    expect(find.text('Planned'), findsOneWidget);
    expect(find.text('Nothing planned yet'), findsNWidgets(2));

    await tester.tap(find.text('Mark cooked'));
    await tester.pumpAndSettle();
    expect(find.text('Cooked'), findsOneWidget);

    await tester.tap(find.text('Mark eaten'));
    await tester.pumpAndSettle();
    expect(find.text('Eaten'), findsOneWidget);
    expect(find.text('Mark eaten'), findsNothing);
  });

  testWidgets('adding to a taken slot asks before replacing', (tester) async {
    await pumpApp(tester);
    await addToToday(tester, 'Varan', 'Lunch');

    // Back to the list, then add Pithla to the same slot.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pithla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to today'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Lunch'));
    await tester.pumpAndSettle();

    expect(find.text('Replace Lunch?'), findsOneWidget);
    expect(find.text('Varan will be replaced with Pithla.'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await goHome(tester);
    expect(find.text('Varan'), findsOneWidget, reason: 'cancel keeps Varan');

    // Again, this time confirming.
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to today'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Lunch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();

    await goHome(tester);
    expect(find.text('Pithla'), findsOneWidget);
    expect(find.text('Varan'), findsNothing);
  });

  testWidgets('remove empties the slot', (tester) async {
    await pumpApp(tester);
    await addToToday(tester, 'Kanda Poha', 'Breakfast');
    await goHome(tester);
    expect(find.text('Kanda Poha'), findsOneWidget);

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from today'));
    await tester.pumpAndSettle();

    expect(find.text('Kanda Poha'), findsNothing);
    expect(find.text('Nothing planned yet'), findsNWidgets(3));
  });
}
