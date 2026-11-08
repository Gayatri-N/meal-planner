import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/core/helpers/app_exception.dart';
import 'package:mealplanner/core/helpers/result.dart';
import 'package:mealplanner/design_system/view_state.dart';
import 'package:mealplanner/domain/models/catalog.dart';
import 'package:mealplanner/domain/repositories/catalog_repository.dart';
import 'package:mealplanner/domain/use_cases/get_recipe_use_case.dart';
import 'package:mealplanner/domain/use_cases/search_recipes_use_case.dart';
import 'package:mealplanner/features/recipes/bloc/recipe_detail_bloc.dart';
import 'package:mealplanner/features/recipes/bloc/recipes_bloc.dart';

/// Fails the first [failures] loads, then returns an empty catalog.
class _FakeCatalogRepository implements CatalogRepository {
  _FakeCatalogRepository({this.failures = 0});

  int failures;

  @override
  Future<Result<Catalog>> load() async {
    if (failures > 0) {
      failures--;
      return const Failure(
        AppException(kind: AppExceptionKind.invalidData, message: 'broken'),
      );
    }
    return Success(Catalog(version: 1, ingredients: [], recipes: []));
  }
}

void main() {
  group('RecipeDetailBloc', () {
    blocTest<RecipeDetailBloc, RecipeDetailState>(
      'reports notFound for an unknown recipe id',
      build: () => RecipeDetailBloc(GetRecipeUseCase(_FakeCatalogRepository())),
      act: (bloc) => bloc.add(const RecipeDetailStarted('no_such_recipe')),
      expect: () => [
        const RecipeDetailState(
          viewState: ViewState.error,
          errorKind: AppExceptionKind.notFound,
        ),
      ],
    );
  });

  group('RecipesBloc', () {
    blocTest<RecipesBloc, RecipesState>(
      'clears the error once a later search succeeds',
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
        const RecipesState(viewState: ViewState.error, query: 'poha'),
        const RecipesState(viewState: ViewState.empty, query: 'poha'),
      ],
    );
  });
}
