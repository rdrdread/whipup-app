import 'package:freezed_annotation/freezed_annotation.dart';
import 'stock_category.dart';

part 'ocr_result.freezed.dart';
part 'ocr_result.g.dart';

/// OCR 인식 결과 DTO.
///
/// Phase 1.2 카메라 영수증 인식 후 생성되는 데이터 전달 객체.
@freezed
abstract class OcrResult with _$OcrResult {
  const factory OcrResult({
    /// OCR에서 파싱된 재료 후보 목록
    required List<OcrIngredientCandidate> candidates,

    /// 원본 인식 텍스트
    required String rawText,
  }) = _OcrResult;

  factory OcrResult.fromJson(Map<String, dynamic> json) =>
      _$OcrResultFromJson(json);
}

/// OCR에서 파싱된 재료 후보 항목.
@freezed
abstract class OcrIngredientCandidate with _$OcrIngredientCandidate {
  const factory OcrIngredientCandidate({
    /// 재료명
    required String name,

    /// 수량 (인식된 경우)
    String? quantity,

    /// 단위 (인식된 경우)
    String? unit,

    /// 추정 카테고리
    @Default(StockCategory.other) StockCategory category,

    /// 사용자가 선택했는지 여부 (결과 확인 화면에서 토글 가능)
    @Default(true) bool isSelected,
  }) = _OcrIngredientCandidate;

  factory OcrIngredientCandidate.fromJson(Map<String, dynamic> json) =>
      _$OcrIngredientCandidateFromJson(json);
}
