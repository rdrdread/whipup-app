/// Result 패턴: 모든 비동기 작업의 성공/실패를 명시적으로 처리한다.
///
/// 사용 예:
/// ```dart
/// Future<Result<Recipe, AppError>> fetchRecipe(String id) async {
///   try {
///     final data = await api.getRecipe(id);
///     return Result.success(data);
///   } catch (e) {
///     return Result.failure(AppError.network(e.toString()));
///   }
/// }
///
/// final result = await fetchRecipe('123');
/// result.when(
///   success: (recipe) => print(recipe.title),
///   failure: (error) => print(error.message),
/// );
/// ```
sealed class Result<T, E> {
  const Result();

  /// 성공 결과를 생성한다.
  const factory Result.success(T value) = Success<T, E>;

  /// 실패 결과를 생성한다.
  const factory Result.failure(E error) = Failure<T, E>;

  /// 성공/실패 여부에 따라 다른 값을 반환한다.
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  });

  /// 성공이면 true.
  bool get isSuccess => this is Success<T, E>;

  /// 실패이면 true.
  bool get isFailure => this is Failure<T, E>;

  /// 성공 값을 반환하거나 null.
  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failure() => null,
      };

  /// 에러 값을 반환하거나 null.
  E? get errorOrNull => switch (this) {
        Success() => null,
        Failure(:final error) => error,
      };
}

/// 성공 케이스.
final class Success<T, E> extends Result<T, E> {
  const Success(this.value);
  final T value;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) =>
      success(value);
}

/// 실패 케이스.
final class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);
  final E error;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) =>
      failure(error);
}
