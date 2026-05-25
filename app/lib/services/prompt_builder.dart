import 'package:whipup/models/stock_item.dart';

/// Gemini API 프롬프트 생성 서비스.
///
/// 재고 재료 목록 → 구조화된 레시피 생성 프롬프트 변환.
/// 응답은 반드시 product_map.md §2.1의 JSON 스키마를 준수해야 한다.
class PromptBuilder {
  const PromptBuilder();

  /// 레시피 생성 프롬프트 생성.
  ///
  /// [items] 선택된 재고 재료 목록
  /// [recipeType] 원하는 레시피 종류 (null = 제한 없음)
  /// [difficulty] 원하는 난이도 (null = 제한 없음)
  /// [servings] 인분 수
  String buildRecipePrompt({
    required List<StockItem> items,
    String? recipeType,
    String? difficulty,
    int servings = 2,
  }) {
    final ingredientList = items
        .map((i) => '- ${i.name} (${i.quantity}${i.unit})')
        .join('\n');

    final typeConstraint = recipeType != null
        ? '레시피 종류는 반드시 "$recipeType"이어야 합니다.'
        : '레시피 종류(recipe_type)는 상황에 맞는 것으로 자유롭게 선택하세요.';

    final difficultyConstraint = difficulty != null
        ? '난이도는 반드시 "$difficulty"이어야 합니다.'
        : '난이도는 재료 조합에 적합한 것으로 선택하세요.';

    return '''
당신은 전문 요리사이자 식품 과학자입니다.
아래 재료를 사용하여 맛있고 근사한 요리 레시피를 JSON 형식으로 생성하세요.

## 보유 재료 (${items.length}가지):
$ingredientList

## 조건:
- 인분 수: $servings인분
- $typeConstraint
- $difficultyConstraint
- 7단계 조리 구조(prep→heat→base→main→season→finish→plate)를 반드시 포함할 것
- 조리 원리(마이야르 반응, 삼투압 등) 과학적 설명을 science_note에 포함할 것
- 맛 프로필(umami, sweet, sour, salty, spicy)을 0~5 정수로 평가할 것
- 대체 가능한 재료는 is_optional: true로 표시할 것

## 필수 JSON 스키마:
{
  "id": "UUID v4 형식",
  "title": "레시피명",
  "description": "한 줄 설명",
  "recipe_type": "main|side|soup|dessert|snack|drink|sauce",
  "servings": 정수,
  "cooking_time_minutes": 정수,
  "difficulty": "easy|medium|hard",
  "ingredients": [
    {"name": "재료명", "amount": "수량", "unit": "단위", "is_optional": false}
  ],
  "steps": [
    {
      "step_number": 1,
      "phase": "prep|heat|base|main|season|finish|plate",
      "description": "단계 설명",
      "duration_seconds": null 또는 정수,
      "tip": null 또는 "팁",
      "media_url": null,
      "media_type": null
    }
  ],
  "tags": ["태그1", "태그2"],
  "flavor_profile": {"umami": 0~5, "sweet": 0~5, "sour": 0~5, "salty": 0~5, "spicy": 0~5},
  "science_note": "요리 과학 설명 또는 null",
  "sources": []
}

순수 JSON만 응답하세요. 마크다운 코드 블록, 설명 텍스트 없이 JSON 객체만 출력하세요.
''';
  }
}
