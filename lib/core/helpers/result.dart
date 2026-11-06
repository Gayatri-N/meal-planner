import 'app_exception.dart';

/// Outcome of an operation that can fail in an expected way.
///
/// Use instead of throwing for failures the caller must handle
/// (permission denied, invalid data, network required).
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) success,
    required R Function(AppException error) failure,
  }) => switch (this) {
    Success<T>(:final value) => success(value),
    Failure<T>(:final error) => failure(error),
  };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success<T>(:final value) => Success(transform(value)),
    Failure<T>(:final error) => Failure(error),
  };
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppException error;
}
