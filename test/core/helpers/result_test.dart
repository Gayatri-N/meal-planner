import 'package:flutter_test/flutter_test.dart';
import 'package:mealplanner/core/helpers/app_exception.dart';
import 'package:mealplanner/core/helpers/result.dart';

void main() {
  group('Result', () {
    const error = AppException(
      kind: AppExceptionKind.notFound,
      message: 'Recipe not found',
    );

    test('when picks the success branch', () {
      const Result<int> result = Success(2);
      expect(
        result.when(success: (v) => 'ok $v', failure: (_) => 'fail'),
        'ok 2',
      );
    });

    test('when picks the failure branch', () {
      const Result<int> result = Failure(error);
      expect(
        result.when(success: (_) => 'ok', failure: (e) => e.message),
        'Recipe not found',
      );
    });

    test('map transforms success and keeps failure', () {
      const Result<int> ok = Success(2);
      const Result<int> failed = Failure(error);

      expect((ok.map((v) => v * 10) as Success<int>).value, 20);
      expect((failed.map((v) => v * 10) as Failure<int>).error, error);
    });
  });
}
