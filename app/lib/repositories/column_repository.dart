import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/column_article.dart';
import 'package:whipup/models/column_category.dart';

/// 칼럼 데이터 접근 추상 인터페이스.
///
/// - MVP: 로컬 JSON 번들 직독 ([LocalColumnRepository])
/// - Phase 2.6+: Remote API 구현체로 교체 예정
abstract class ColumnRepository {
  /// 전체 칼럼 목록 (최신 발행순).
  Future<Result<List<ColumnArticle>, AppError>> getAll();

  /// 카테고리 필터 적용 목록.
  Future<Result<List<ColumnArticle>, AppError>> getByCategory(
    ColumnCategory category,
  );

  /// ID로 단일 칼럼 조회.
  Future<Result<ColumnArticle, AppError>> getById(String id);
}
