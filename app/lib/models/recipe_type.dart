// ignore_for_file: constant_identifier_names

/// 레시피 분류, 조리 단계, 난이도 Enum 정의.
///
/// 데이터 계약: `docs/core/product_map.md §2.3`
library;

// ─── RecipeType ─────────────────────────────────────────────────────────────

/// 레시피 분류 타입 (7가지).
enum RecipeType {
  main('주요리'),
  side('반찬'),
  soup('국·찌개·탕'),
  dessert('후식·디저트'),
  snack('간식'),
  drink('음료·주스'),
  sauce('소스·드레싱');

  const RecipeType(this.label);

  /// 한글 표시명
  final String label;
}

// ─── CookingPhase ─────────────────────────────────────────────────────────

/// 7단계 조리 단계.
///
/// 단계 정의: `docs/core/product_map.md §2.2`
enum CookingPhase {
  prep('재료 손질'),
  heat('기름·불 세팅'),
  base('베이스 조리'),
  main('메인 조리'),
  season('간 맞추기'),
  finish('마무리'),
  plate('플레이팅');

  const CookingPhase(this.label);

  /// 한글 표시명
  final String label;
}

// ─── RecipeDifficulty ───────────────────────────────────────────────────────

/// 레시피 난이도.
enum RecipeDifficulty {
  easy('쉬움'),
  medium('보통'),
  hard('어려움');

  const RecipeDifficulty(this.label);

  /// 한글 표시명
  final String label;
}
