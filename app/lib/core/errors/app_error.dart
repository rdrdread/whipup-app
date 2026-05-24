/// 앱 전역 에러 타입.
/// Result<T, AppError> 형태로 사용한다.
sealed class AppError {
  const AppError();

  /// 네트워크/API 통신 오류
  const factory AppError.network(String message) = NetworkError;

  /// 로컬 DB 오류
  const factory AppError.database(String message) = DatabaseError;

  /// AI 응답 파싱 오류
  const factory AppError.parsing(String message) = ParsingError;

  /// 알 수 없는 오류
  const factory AppError.unknown(Object cause) = UnknownError;

  String get message;
}

final class NetworkError extends AppError {
  const NetworkError(this.message);

  @override
  final String message;
}

final class DatabaseError extends AppError {
  const DatabaseError(this.message);

  @override
  final String message;
}

final class ParsingError extends AppError {
  const ParsingError(this.message);

  @override
  final String message;
}

final class UnknownError extends AppError {
  const UnknownError(this.cause);
  final Object cause;

  @override
  String get message => cause.toString();
}
