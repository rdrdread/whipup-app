import 'package:freezed_annotation/freezed_annotation.dart';
import 'recipe_type.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

// ─── Recipe ──────────────────────────────────────────────────────────────────

/// 레시피 도메인 모델.
///
/// JSON 스키마 7단계 조리 구조: `docs/core/product_map.md §2.1`
/// AI가 생성하는 모든 레시피는 이 스키마를 준수해야 한다.
@freezed
abstract class Recipe with _$Recipe {
  const Recipe._();

  const factory Recipe({
    /// 레시피 고유 ID (UUID)
    required String id,

    /// 레시피 이름
    required String title,

    /// 레시피 설명
    required String description,

    /// 레시피 분류
    required RecipeType recipeType,

    /// 인분 수
    required int servings,

    /// 조리 시간 (분)
    required int cookingTimeMinutes,

    /// 난이도
    required RecipeDifficulty difficulty,

    /// 재료 목록
    required List<RecipeIngredient> ingredients,

    /// 조리 단계 (7단계)
    required List<RecipeStep> steps,

    /// 태그 목록
    @Default([]) List<String> tags,

    /// 맛 프로필
    required FlavorProfile flavorProfile,

    /// 요리 과학 설명 (선택)
    String? scienceNote,

    /// 출처 목록
    @Default([]) List<String> sources,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);

  /// 전체 조리 단계 수.
  int get totalSteps => steps.length;

  /// 특정 단계를 반환한다.
  RecipeStep? stepAt(int index) =>
      index >= 0 && index < steps.length ? steps[index] : null;
}

// ─── RecipeIngredient ────────────────────────────────────────────────────────

/// 레시피 재료 모델.
@freezed
abstract class RecipeIngredient with _$RecipeIngredient {
  const factory RecipeIngredient({
    /// 재료명
    required String name,

    /// 수량 (문자열로 표현)
    required String amount,

    /// 단위
    required String unit,

    /// 선택 재료 여부
    @Default(false) bool isOptional,
  }) = _RecipeIngredient;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientFromJson(json);
}

// ─── RecipeStep ──────────────────────────────────────────────────────────────

/// 조리 단계 모델.
@freezed
abstract class RecipeStep with _$RecipeStep {
  const factory RecipeStep({
    /// 단계 번호 (1~7)
    required int stepNumber,

    /// 조리 단계
    required CookingPhase phase,

    /// 단계 설명
    required String description,

    /// 소요 시간 (초). null이면 타이머 없음
    int? durationSeconds,

    /// 조리 팁
    String? tip,

    /// 미디어 URL (영상/이미지)
    String? mediaUrl,

    /// 미디어 타입 ('image' | 'video')
    String? mediaType,
  }) = _RecipeStep;

  factory RecipeStep.fromJson(Map<String, dynamic> json) =>
      _$RecipeStepFromJson(json);
}

// ─── FlavorProfile ───────────────────────────────────────────────────────────

/// 맛 프로필 (각 항목 0~5 정수).
@freezed
abstract class FlavorProfile with _$FlavorProfile {
  const factory FlavorProfile({
    @Default(0) int umami,
    @Default(0) int sweet,
    @Default(0) int sour,
    @Default(0) int salty,
    @Default(0) int spicy,
  }) = _FlavorProfile;

  factory FlavorProfile.fromJson(Map<String, dynamic> json) =>
      _$FlavorProfileFromJson(json);
}
