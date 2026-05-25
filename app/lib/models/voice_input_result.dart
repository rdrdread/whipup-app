import 'package:freezed_annotation/freezed_annotation.dart';
import 'stock_category.dart';

part 'voice_input_result.freezed.dart';
part 'voice_input_result.g.dart';

/// 음성 입력 결과 DTO.
///
/// Phase 1.3 음성 인식 후 생성되는 데이터 전달 객체.
@freezed
abstract class VoiceInputResult with _$VoiceInputResult {
  const factory VoiceInputResult({
    /// 음성 인식 원본 텍스트
    required String transcript,

    /// 파싱된 재료 후보 목록
    required List<VoiceIngredientCandidate> candidates,
  }) = _VoiceInputResult;

  factory VoiceInputResult.fromJson(Map<String, dynamic> json) =>
      _$VoiceInputResultFromJson(json);
}

/// 음성에서 파싱된 재료 후보 항목.
@freezed
abstract class VoiceIngredientCandidate with _$VoiceIngredientCandidate {
  const factory VoiceIngredientCandidate({
    /// 재료명
    required String name,

    /// 수량 (파싱된 경우)
    String? quantity,

    /// 단위 (파싱된 경우)
    String? unit,

    /// 추정 카테고리
    @Default(StockCategory.other) StockCategory category,

    /// 사용자가 선택했는지 여부
    @Default(true) bool isSelected,
  }) = _VoiceIngredientCandidate;

  factory VoiceIngredientCandidate.fromJson(Map<String, dynamic> json) =>
      _$VoiceIngredientCandidateFromJson(json);
}
