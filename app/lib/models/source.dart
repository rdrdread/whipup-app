import 'package:freezed_annotation/freezed_annotation.dart';

part 'source.freezed.dart';
part 'source.g.dart';

/// 출처 유형.
enum SourceType {
  /// 학술 논문 (DOI 권장)
  paper,

  /// 정부·공공기관 가이드 (식약처, USDA, WHO 등)
  government,

  /// 전문 서적
  book,

  /// 신뢰 기관 뉴스·매거진
  news,
}

/// 칼럼 출처 정보.
///
/// Editor가 1차 출처(논문/식약처/USDA 등)를 기재한다.
/// 필드 정의: `docs/features/weekly_column.md §3.1`
@freezed
abstract class Source with _$Source {
  const factory Source({
    /// 인용 텍스트 (예: "K. Miglio et al., 2008")
    required String citation,

    /// 출처 URL (논문 DOI, 공공기관 링크 등). 없으면 null.
    String? url,

    /// 출처 유형
    @Default(SourceType.paper) SourceType type,
  }) = _Source;

  factory Source.fromJson(Map<String, dynamic> json) => _$SourceFromJson(json);
}
