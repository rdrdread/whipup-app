import 'package:freezed_annotation/freezed_annotation.dart';

import 'column_category.dart';
import 'source.dart';

part 'column_article.freezed.dart';
part 'column_article.g.dart';

/// 위클리 칼럼 아티클 도메인 모델.
///
/// Editor가 작성·검수한 콘텐츠를 그대로 역직렬화한다.
/// 필드 정의: `docs/core/product_map.md §3.3`
@freezed
abstract class ColumnArticle with _$ColumnArticle {
  const factory ColumnArticle({
    /// 고유 ID (예: col_001)
    required String id,

    /// 칼럼 제목
    required String title,

    /// 부제
    required String subtitle,

    /// 본문 (플레인 텍스트, 단락 구분은 '\n\n')
    required String body,

    /// 카테고리
    required ColumnCategory category,

    /// 태그 목록
    @Default(<String>[]) List<String> tags,

    /// 출처 목록
    @Default(<Source>[]) List<Source> sources,

    /// 대표 이모지
    required String thumbnailEmoji,

    /// 발행일
    required DateTime publishedAt,

    /// 예상 읽기 시간 (분)
    @Default(3) int readingTimeMinutes,
  }) = _ColumnArticle;

  factory ColumnArticle.fromJson(Map<String, dynamic> json) =>
      _$ColumnArticleFromJson(json);
}
