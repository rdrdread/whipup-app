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
- 인분 수: $servings인분 (모든 재료 수량을 반드시 $servings인분 기준으로 계산할 것)
- $typeConstraint
- $difficultyConstraint
- 7단계 조리 구조(prep→heat→base→main→season→finish→plate)를 반드시 포함할 것
- 조리 원리(마이야르 반응, 삼투압 등) 과학적 설명을 science_note에 포함할 것
- 맛 프로필(umami, sweet, sour, salty, spicy)을 0~5 정수로 평가할 것
- 대체 가능한 재료는 is_optional: true로 표시할 것

## 재료 수량 형식 규칙 (필수):
- "amount" 필드: 반드시 순수 숫자 문자열만 사용. 예: "2", "0.5", "1/2", "1 1/2"
  - 단위는 절대 amount에 포함하지 말 것 ("2컵" ❌ → amount: "2", unit: "컵" ✅)
  - 계량 불가 재료(소금 약간, 후추 조금 등)만 예외적으로 "약간" 또는 "적당량" 허용
- "unit" 필드: 단위만 기재. 예: "g", "ml", "컵", "큰술", "작은술", "개", "장", "줄기", "마리"(생선·갑각류), "알"(달걀류)
  - 단위가 없으면 빈 문자열 "" 사용

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
    {"name": "재료명", "amount": "순수숫자_또는_약간", "unit": "단위_또는_빈문자열", "is_optional": false}
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

  /// 요리명 기반 레시피 생성 프롬프트.
  ///
  /// [dishName] 생성할 요리 이름 (예: '된장찌개')
  /// [servings] 인분 수
  String buildByDishName(String dishName, {int servings = 2}) {
    return '''
당신은 전문 요리사이자 식품 과학자입니다.
아래 요리의 정통 한국 가정식 레시피를 JSON 형식으로 생성하세요.

## 요리명: $dishName
## 인분: $servings인분 (모든 재료 수량을 반드시 $servings인분 기준으로 계산할 것)

## 조건:
- 7단계 조리 구조(prep→heat→base→main→season→finish→plate)를 반드시 포함할 것
- 조리 원리(마이야르 반응, 삼투압 등) 과학적 설명을 science_note에 포함할 것
- 맛 프로필(umami, sweet, sour, salty, spicy)을 0~5 정수로 평가할 것
- 대체 가능한 재료는 is_optional: true로 표시할 것

## 재료 수량 형식 규칙 (필수):
- "amount" 필드: 반드시 순수 숫자 문자열만 사용. 예: "2", "0.5", "1/2"
  - 단위는 절대 amount에 포함하지 말 것
  - 계량 불가 재료(소금 약간 등)만 예외적으로 "약간" 또는 "적당량" 허용
- "unit" 필드: 단위만 기재. 예: "g", "ml", "개", "마리"(생선·갑각류), "알"(달걀류). 단위가 없으면 빈 문자열 "" 사용

## 필수 JSON 스키마:
{
  "id": "UUID v4 형식",
  "title": "$dishName",
  "description": "한 줄 설명",
  "recipe_type": "main|side|soup|dessert|snack|drink|sauce",
  "servings": $servings,
  "cooking_time_minutes": 정수,
  "difficulty": "easy|medium|hard",
  "ingredients": [
    {"name": "재료명", "amount": "순수숫자_또는_약간", "unit": "단위_또는_빈문자열", "is_optional": false}
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

  /// 요리 영상 URL 기반 레시피 추출 프롬프트.
  ///
  /// YouTube 등 요리 영상에서 레시피를 분석·추출하도록 지시한다.
  /// [videoUrl]은 YouTube 외 URL의 경우 텍스트 컨텍스트로 포함된다.
  String buildVideoRecipePrompt(String videoUrl) {
    return '''
당신은 전문 요리사이자 식품 과학자입니다.
위 요리 영상을 처음부터 끝까지 꼼꼼히 분석한 뒤, 아래 JSON 형식으로 레시피를 추출해 주세요.

## 분석 방법 (순서대로 실행):
1. 영상 전체를 처음부터 끝까지 시청하며 모든 재료·조리 동작을 파악한다.
2. 영상에 등장하는 모든 조리 행동을 아래 7개 phase 중 하나로 분류한다.
3. 같은 phase에 속한 여러 행동은 하나의 description으로 통합한다.
4. 반드시 prep→heat→base→main→season→finish→plate 순서로 정렬하여 출력한다.

## 7단계 phase 정의 (steps 배열에 정확히 이 순서대로, 7개만 출력):
- step_number 1 / phase "prep"   : 재료 손질·계량·밑준비 (씻기, 썰기, 재우기, 계량 등)
- step_number 2 / phase "heat"   : 조리 도구 가열 (팬/냄비 달구기, 기름 두르기, 물 끓이기)
- step_number 3 / phase "base"   : 베이스 만들기 (육수, 소스 베이스, 마늘·파 등 향신료 볶기)
- step_number 4 / phase "main"   : 주재료 조리 (주재료 넣고 굽기·볶기·끓이기·튀기기)
- step_number 5 / phase "season" : 간·양념 조절 (양념 추가, 소금·간장·설탕 등으로 맛 맞추기)
- step_number 6 / phase "finish" : 마무리 조리 (졸이기, 뚜껑 덮어 찌기, 불 세기 조절, 최종 가열)
- step_number 7 / phase "plate"  : 완성·담기 (그릇에 담기, 가니쉬·고명 얹기, 완성 장식)

## steps 작성 규칙 (반드시 준수):
- steps 배열은 정확히 7개 항목이어야 합니다.
- phase 값은 반드시 위 정의 순서 그대로: prep, heat, base, main, season, finish, plate
- step_number는 1~7 순서 그대로이어야 합니다.
- 영상에서 해당 phase가 짧거나 생략된 경우에도 이 요리의 특성에 맞게 합리적으로 채웁니다.
- 영상의 실제 요리명·재료·조리법을 최우선으로 반영합니다.
- video_timestamp_seconds: 해당 단계가 영상에서 시작되는 타임스탬프(초). 영상 전체 길이에 맞게 추정.

## 재료 수량 형식 (필수):
- "amount": 순수 숫자 문자열만. 예: "2", "0.5". 단위 포함 금지. 계량 불가만 "약간" 허용.
- "unit": 단위만. 예: "g", "ml", "개". 없으면 빈 문자열 "".

## JSON 스키마:
{
  "id": "UUID v4",
  "title": "레시피명",
  "description": "한 줄 설명",
  "recipe_type": "main|side|soup|dessert|snack|drink|sauce",
  "servings": 정수,
  "cooking_time_minutes": 정수,
  "difficulty": "easy|medium|hard",
  "ingredients": [{"name": "재료명", "amount": "숫자", "unit": "단위", "is_optional": false}],
  "steps": [
    {"step_number": 1, "phase": "prep",   "description": "설명", "duration_seconds": null, "tip": null, "media_url": null, "media_type": null, "video_timestamp_seconds": 정수},
    {"step_number": 2, "phase": "heat",   "description": "설명", "duration_seconds": null, "tip": null, "media_url": null, "media_type": null, "video_timestamp_seconds": 정수},
    {"step_number": 3, "phase": "base",   "description": "설명", "duration_seconds": null, "tip": null, "media_url": null, "media_type": null, "video_timestamp_seconds": 정수},
    {"step_number": 4, "phase": "main",   "description": "설명", "duration_seconds": null, "tip": null, "media_url": null, "media_type": null, "video_timestamp_seconds": 정수},
    {"step_number": 5, "phase": "season", "description": "설명", "duration_seconds": null, "tip": null, "media_url": null, "media_type": null, "video_timestamp_seconds": 정수},
    {"step_number": 6, "phase": "finish", "description": "설명", "duration_seconds": null, "tip": null, "media_url": null, "media_type": null, "video_timestamp_seconds": 정수},
    {"step_number": 7, "phase": "plate",  "description": "설명", "duration_seconds": null, "tip": null, "media_url": null, "media_type": null, "video_timestamp_seconds": 정수}
  ],
  "tags": ["태그1", "태그2"],
  "flavor_profile": {"umami": 0~5, "sweet": 0~5, "sour": 0~5, "salty": 0~5, "spicy": 0~5},
  "science_note": "요리 과학 설명",
  "sources": []
}

순수 JSON만 응답하세요. 마크다운 코드 블록, 설명 텍스트 없이 JSON 객체만 출력하세요.
''';
  }

  /// 음성 인식 텍스트 → 재료 목록 파싱 프롬프트.
  ///
  /// Gemini가 자연어 발화에서 재료명·수량·단위·카테고리만 추론한다.
  /// 보관 위치와 유통기한은 VoiceGeminiParser가 로컬에서 추론한다.
  String buildVoiceParsingPrompt(String transcript) {
    return '''
한국 식재료 전문가로서 아래 음성 인식 텍스트에서 식재료를 빠짐없이 추출해 JSON 배열로 반환하세요.
음성 인식 오류(발음 유사어·띄어쓰기 오류·축약어)가 있을 수 있으니 문맥상 가장 가능성 높은 식재료명으로 해석하세요.
식재료가 여러 개면 배열에 모두 포함하세요.

음성: "$transcript"

수량 해석:
- 순우리말: 하나=1, 둘=2, 셋=3, 넷=4, 다섯=5, 여섯=6, 일곱=7, 여덟=8, 아홉=9, 열=10, 스물=20, 서른=30
- 한자어: 일=1, 이=2, 삼=3, 사=4, 오=5, 육=6, 칠=7, 팔=8, 구=9, 십=10, 백=100, 천=1000
- 복합: 삼백=300, 이백오십=250, 오백=500, 천오백=1500
- 단위 표현: 한 판/한판=10개, 한 팩/한봉/한봉지=1, 반=0.5, 한 다발=1묶음, 한 줄=1줄
- category: meat|seafood|vegetable|fruit|dairy|grain|seasoning|beverage|frozen|other
- 단위: g|kg|ml|L|개|알|마리|봉|봉지|팩|캔|병|컵|줄|장|묶음|쪽|통|덩이 (없으면 "")

순수 JSON 배열만 반환 (마크다운 없이):
[{"name":"돼지고기","quantity":"300","unit":"g","category":"meat"},{"name":"계란","quantity":"10","unit":"개","category":"dairy"}]
''';
  }
}
