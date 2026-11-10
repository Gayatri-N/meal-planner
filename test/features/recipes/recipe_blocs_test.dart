import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/core/helpers/app_exception.dart';
import 'package:mealplanner/core/helpers/result.dart';
import 'package:mealplanner/design_system/view_state.dart';
import 'package:mealplanner/domain/models/catalog.dart';
import 'package:mealplanner/domain/models/meal_type.dart';
import 'package:mealplanner/domain/models/recipe.dart';
import 'package:mealplanner/domain/repositories/catalog_repository.dart';
import 'package:mealplanner/domain/use_cases/get_recipe_use_case.dart';
import 'package:mealplanner/domain/use_cases/search_recipes_use_case.dart';
import 'package:mealplanner/features/recipes/bloc/recipe_detail_bloc.dart';
import 'package:mealplanner/features/recipes/bloc/recipes_bloc.dart';
import 'package:mealplanner/core/helpers/id_generator.dart';
import 'package:mealplanner/data/repositories/local_day_repository.dart';
import 'package:mealplanner/domain/use_cases/add_recipe_to_meal_use_case.dart';

import '../../helpers/fakes.dart';

RecipeDetailBloc _detailBloc(GetRecipeUseCase getRecipe) => RecipeDetailBloc(
  getRecipe,
  AddRecipeToMealUseCase(
    LocalDayRepository(tempStore(addTearDown: addTearDown)),
    FixedClock(DateTime(2026, 11, 9, 12)),
    IdGenerator.seeded(1),
    RecordingAnalytics(),
    RecordingCrash(),
  ),
);

/// Fails the first [failures] loads, then returns [recipes].
class _FakeCatalogRepository implements CatalogRepository {
  _FakeCatalogRepository({this.failures = 0, this.recipes = const []});

  int failures;
  final List<Recipe> recipes;

  @override
  Future<Result<Catalog>> load() async {
    if (failures > 0) {
      failures--;
      return const Failure(
        AppException(kind: AppExceptionKind.invalidData, message: 'broken'),
      );
    }
    return Success(Catalog(version: 1, ingredients: [], recipes: recipes));
  }
}

Recipe _recipe({required String id, required int baseServings}) => Recipe(
  id: id,
  nameEn: 'Festival batch',
  nameMr: 'सणाचा बेत',
  aliases: const [],
  mealTypes: const [MealType.lunch],
  diet: Diet.veg,
  baseServings: baseServings,
  prepMinutes: 0,
  cookMinutes: 0,
  regionIds: const ['pune'],
  seasonTags: const [],
  festivalTags: const [],
  occasionTags: const [],
  ingredientLines: const [],
  steps: const [],
  contentStatus: ContentStatus.draft,
);

void main() {
  group('RecipeDetailBloc', () {
    blocTest<RecipeDetailBloc, RecipeDetailState>(
      'reports notFound for an unknown recipe id',
      build: () => _detailBloc(GetRecipeUseCase(_FakeCatalogRepository())),
      act: (bloc) => bloc.add(const RecipeDetailStarted('no_such_recipe')),
      expect: () => [
        const RecipeDetailState(
          viewState: ViewState.error,
          errorKind: AppExceptionKind.notFound,
        ),
      ],
    );

    blocTest<RecipeDetailBloc, RecipeDetailState>(
      'starts servings within the stepper range',
      build: () => _detailBloc(
        GetRecipeUseCase(
          _FakeCatalogRepository(
            recipes: [_recipe(id: 'big', baseServings: 25)],
          ),
        ),
      ),
      act: (bloc) => bloc.add(const RecipeDetailStarted('big')),
      verify: (bloc) => expect(bloc.state.servings, maxServings),
    );

    blocTest<RecipeDetailBloc, RecipeDetailState>(
      'quick repeated taps each add a serving',
      build: () => _detailBloc(
        GetRecipeUseCase(
          _FakeCatalogRepository(
            recipes: [_recipe(id: 'two', baseServings: 2)],
          ),
        ),
      ),
      act: (bloc) async {
        bloc.add(const RecipeDetailStarted('two'));
        await Future<void>.delayed(Duration.zero);
        // Added back to back, before either is handled.
        bloc
          ..add(const RecipeServingsStepped(1))
          ..add(const RecipeServingsStepped(1));
      },
      verify: (bloc) => expect(bloc.state.servings, 4),
    );
  });

  group('RecipesBloc', () {
    blocTest<RecipesBloc, RecipesState>(
      'shows loading while retrying after an error, then clears the error',
      build: () => RecipesBloc(
        SearchRecipesUseCase(_FakeCatalogRepository(failures: 1)),
      ),
      act: (bloc) async {
        bloc.add(const RecipesStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RecipesQueryChanged('poha'));
      },
      wait: RecipesBloc.searchDebounce * 2,
      skip: 1, // initial query echo
      expect: () => [
        const RecipesState(
          viewState: ViewState.error,
          errorKind: AppExceptionKind.invalidData,
        ),
        const RecipesState(viewState: ViewState.loading, query: 'poha'),
        const RecipesState(viewState: ViewState.empty, query: 'poha'),
      ],
    );
  });
}
