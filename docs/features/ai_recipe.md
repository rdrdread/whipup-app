# AI 레시피 추천 (Phase 1.1)

> **Phase:** 1.1
> **선행 조건:** Phase 1.0 완료 (StockItem 모델, Isar 인프라)
> **참조 에이전트:** Architect (모델/Provider), Artisan (UI/애니메이션), Bridge (Gemini API/캐시)
> **상위 문서:** `roadmap.md §3`, `product_map.md §2`, `product_map.md §5.2`

---

## 1. Feature Summary

사용자가 보유 재료를 선택하면 Gemini 1.5 Pro가 7단계 조리 구조의 레시피 JSON을 생성하는 AI 추천 기능.

> **Design Creed 연결:** *"레시피는 정답이 아니라, 영감을 위한 악보일 뿐."*
> AI가 생성하는 레시피는 고정된 답안이 아니라 사용자의 창의적 변주를 촉진하는 출발점으로 설계한다.
> 복잡한 AI 분석 과정은 로딩 애니메이션 뒤로 숨기고, 사용자 눈에는 근사한 레시피 카드만 보인다.

캐시 우선순위 (`CLAUDE.md §3.3`):
```
Local Isar Cache → Server Cache (Phase 2.0+) → Gemini API 생성
```

---

## 2. User Stories

### US-1: 보유 재료로 레시피 추천 받기
> "지금 냉장고에 있는 재료로 뭘 만들 수 있을지 AI한테 물어보고 싶다."

- **Given:** 재고가 1개 이상 등록된 상태에서 `/recipe` 탭 진입
- **When:** 원하는 재료를 선택하고 [레시피 추천 받기] CTA를 탭
- **Then:** 로딩 Lottie(cooking)가 재생되며 Gemini API 요청
- **And:** 최대 3개의 `RecipeCard`가 슬라이드-업 애니메이션과 함께 표시
- **And:** `HapticFeedback.mediumImpact()` + 성공 Lottie 1회 재생

### US-2: 레시피 상세 조리 가이드 보기
> "단계별로 어떻게 만드는지 자세히 알고 싶다."

- **Given:** RecipeCard 목록에서 카드를 탭
- **When:** 상세 화면(`/recipe/:id`)으로 이동
- **Then:** 7단계 CookingStepItem이 순서대로 표시
- **And:** 각 단계의 `duration_seconds` > 0이면 타이머 버튼 표시

### US-3: 조리 단계 타이머
> "3분 볶으라고 하는데 타이머를 직접 켜기 귀찮다."

- **Given:** 레시피 상세 화면에서 duration_seconds가 있는 단계
- **When:** [⏱ 타이머 시작] 버튼 탭
- **Then:** 해당 단계 내부에 카운트다운 타이머가 인라인으로 표시 (`displayMedium` 스타일)
- **And:** 완료 시 `HapticFeedback.vibrate()` + 사운드 알림

### US-4: 즐겨찾기
> "이 레시피 나중에도 또 만들고 싶다."

- **Given:** 레시피 상세 화면의 AppBar ❤️ 버튼
- **When:** 탭
- **Then:** Isar 로컬에 즐겨찾기 저장 + ❤️ 채워짐 애니메이션
- **And:** `HapticFeedback.lightImpact()`

### US-5: recipe_type 필터
> "오늘은 국물 요리가 먹고 싶다."

- **Given:** 레시피 추천 화면의 옵션 섹션
- **When:** recipe_type 드롭다운에서 [국·찌개] 선택
- **Then:** 해당 type의 레시피만 추천

### US-6: 재료 대체 제안
> "레시피에 청주가 필요한데 없어. 뭘로 대체하지?"

- **Given:** 레시피 상세에서 보유하지 않은 재료 (⬜ 표시)
- **When:** 해당 재료 행 탭
- **Then:** "대체 재료 힌트" 바텀시트 표시
  - 예: "청주 → 맛술, 소주(1/2량), 또는 생략 가능"
  - `science_note` 스타일 callout 디자인
- **And:** 이 힌트는 Gemini의 `tip` 필드에서 파싱

### US-7: 캐시된 레시피 오프라인 열람
> "와이파이가 없는데 저번에 봤던 레시피 다시 보고 싶다."

- **Given:** 네트워크 없음, 이전에 생성된 레시피 존재
- **When:** 동일 재료 조합으로 추천 요청
- **Then:** Isar 캐시에서 즉시 반환 (로딩 없음)
- **And:** "저장된 레시피입니다" 배너 표시

---

## 3. Acceptance Criteria

| # | 기준 | 검증 방법 | 에이전트 |
|---|------|----------|---------|
| AC-1 | 재료 1개 이상 선택 시 CTA 활성화, 0개이면 비활성 | UI 확인 | Artisan |
| AC-2 | 동일 재료 조합 + 동일 recipe_type 요청 시 캐시 반환 | Unit Test | Bridge |
| AC-3 | Gemini 응답이 7단계 JSON 스키마를 준수 | Unit Test | Bridge |
| AC-4 | JSON 파싱 오류 시 최대 2회 재시도 후 에러 UI 표시 | Unit Test | Bridge |
| AC-5 | RecipeCard에 recipe_type 뱃지, 조리 시간, 난이도 표시 | UI 확인 | Artisan |
| AC-6 | 레시피 상세: 7단계 CookingStepItem 전부 표시 | UI 확인 | Artisan |
| AC-7 | FlavorRadar: 5개 축(감칠맛·단맛·신맛·짠맛·매운맛) 시각화 | UI 확인 | Artisan |
| AC-8 | IngredientCheckList: 보유(✅)/미보유(⬜) 구분 | Unit Test | Architect |
| AC-9 | 타이머: duration_seconds 있는 단계에서만 버튼 노출 | UI 확인 | Artisan |
| AC-10 | 즐겨찾기 저장·해제 후 앱 재시작 시 상태 유지 | 수동 테스트 | Bridge |
| AC-11 | 네트워크 없을 때 캐시 레시피 표시 + 배너 안내 | 수동 테스트 | Bridge |
| AC-12 | science_note 있을 때만 🔬 카드 표시 | UI 확인 | Artisan |
| AC-13 | recipe_type 필터 변경 시 즉시 반영 | UI 확인 | Architect |
| AC-14 | AI 응답 Strict JSON 준수 (`CLAUDE.md §3.3`) | Unit Test | Bridge |

---

## 4. Data Requirements (Architect)

> 모든 모델은 Freezed + `fromJson`/`toJson` 포함. `product_map.md §2.1` JSON Schema와 1:1 매핑.

### 4.1. Recipe 모델 (`lib/models/recipe.dart`)

```dart
@freezed
class Recipe with _$Recipe {
  const factory Recipe({
    required String id,              // UUID
    required String title,
    required String description,
    required RecipeType recipeType,  // main|side|soup|dessert|snack|drink|sauce
    required int servings,
    required int cookingTimeMinutes,
    required DifficultyLevel difficulty,
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
    required List<String> tags,
    required FlavorProfile flavorProfile,
    String? scienceNote,
    required List<String> sources,
    @Default(false) bool isFavorite,
    DateTime? cachedAt,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
}
```

### 4.2. 하위 모델

**RecipeStep** (`lib/models/recipe_step.dart`)

```dart
@freezed
class RecipeStep with _$RecipeStep {
  const factory RecipeStep({
    required int stepNumber,        // 1~7
    required CookingPhase phase,    // prep|heat|base|main|season|finish|plate
    required String description,
    int? durationSeconds,
    String? tip,                    // "The Kick" — 감칠맛 설명, 대체 재료 힌트 포함
    String? mediaUrl,
    MediaType? mediaType,           // image|video
  }) = _RecipeStep;

  factory RecipeStep.fromJson(Map<String, dynamic> json) => _$RecipeStepFromJson(json);
}
```

**RecipeIngredient** (`lib/models/recipe_ingredient.dart`)

```dart
@freezed
class RecipeIngredient with _$RecipeIngredient {
  const RecipeIngredient._();

  const factory RecipeIngredient({
    required String name,
    required String amount,
    required String unit,
    @Default(false) bool isOptional,
  }) = _RecipeIngredient;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientFromJson(json);

  /// 보유 재고와 대조하여 소유 여부 반환.
  bool isOwned(List<String> ownedIngredientNames) => ownedIngredientNames.any(
    (name) => name.toLowerCase().contains(this.name.toLowerCase()),
  );
}
```

**FlavorProfile** (`lib/models/flavor_profile.dart`)

```dart
@freezed
class FlavorProfile with _$FlavorProfile {
  const factory FlavorProfile({
    @Default(0) int umami,   // 감칠맛 0~5
    @Default(0) int sweet,   // 단맛
    @Default(0) int sour,    // 신맛
    @Default(0) int salty,   // 짠맛
    @Default(0) int spicy,   // 매운맛
  }) = _FlavorProfile;

  factory FlavorProfile.fromJson(Map<String, dynamic> json) =>
      _$FlavorProfileFromJson(json);
}
```

### 4.3. Enum 정의

**RecipeType** (`lib/models/recipe_type.dart`)

| 값 | 한글 | 이모지 |
|----|------|--------|
| `main` | 주요리 | 🍽️ |
| `side` | 반찬 | 🥘 |
| `soup` | 국·찌개·탕 | 🍲 |
| `dessert` | 후식·디저트 | 🍮 |
| `snack` | 간식 | 🥪 |
| `drink` | 음료·주스 | 🥤 |
| `sauce` | 소스·드레싱 | 🧴 |

**CookingPhase** (`lib/models/cooking_phase.dart`)

| 값 | 번호 | 설명 | 아이콘 |
|----|------|------|--------|
| `prep` | 1 | 재료 손질 (세척, 절단, 계량) | 🔪 |
| `heat` | 2 | 기름·불 세팅 (팬 예열, 물 끓이기) | 🔥 |
| `base` | 3 | 베이스 조리 (향신료, 볶음 시작) | 🧄 |
| `main` | 4 | 메인 재료 투입·조리 | 🥩 |
| `season` | 5 | 간 맞추기 (소금, 간장, 설탕) | 🧂 |
| `finish` | 6 | 마무리 (불 끄기, 버터 마운팅) | ✅ |
| `plate` | 7 | 플레이팅 및 가니시 | 🍴 |

**DifficultyLevel**

| 값 | 한글 | 표시 |
|----|------|------|
| `easy` | 쉬움 | ⭐ |
| `medium` | 보통 | ⭐⭐ |
| `hard` | 어려움 | ⭐⭐⭐ |

**MediaType:** `image`, `video`

### 4.4. 레시피 요청 옵션 모델 (`lib/models/recipe_request.dart`)

```dart
@freezed
class RecipeRequest with _$RecipeRequest {
  const factory RecipeRequest({
    required List<StockItem> ingredients,
    RecipeType? recipeType,           // null = 전체
    DifficultyLevel? difficulty,      // null = 제한 없음
    @Default(2) int servings,
    @Default(false) bool favoriteOnly,
  }) = _RecipeRequest;
}
```

### 4.5. RecipeRepository 인터페이스 (`lib/repositories/recipe_repository.dart`)

```dart
abstract class RecipeRepository {
  /// 재료 조합으로 레시피 생성 (캐시 우선 조회).
  /// Local Cache → Server Cache(Phase 2.0+) → Gemini API
  Future<Result<List<Recipe>, AppError>> generateFromStock(RecipeRequest request);

  /// 캐시된 레시피 전체 조회
  Future<Result<List<Recipe>, AppError>> getCached();

  /// 즐겨찾기 목록 조회
  Future<Result<List<Recipe>, AppError>> getFavorites();

  /// 레시피 즐겨찾기 토글
  Future<Result<void, AppError>> toggleFavorite(String recipeId);

  /// 레시피 캐시 저장
  Future<Result<void, AppError>> saveToCache(Recipe recipe);

  /// 레시피 ID로 조회
  Future<Result<Recipe, AppError>> getById(String id);
}
```

### 4.6. Provider 구조 (`lib/providers/recipe_providers.dart`)

> `product_map.md §5.2` 참조.

| Provider | 타입 | 역할 |
|----------|------|------|
| `selectedIngredientsNotifierProvider` | `Notifier<List<StockItem>>` | 레시피 요청용 선택 재료 목록 |
| `recipeRequestNotifierProvider` | `Notifier<RecipeRequest>` | 옵션(type, difficulty, servings) 상태 |
| `recipeGeneratorProvider` | `AsyncNotifier<List<Recipe>>` | 생성 요청 · 결과 관리 |
| `recipeCacheProvider` | `AsyncNotifier<List<Recipe>>` | 캐시 목록 (홈 슬라이더용) |
| `favoriteRecipesProvider` | `AsyncNotifier<List<Recipe>>` | 즐겨찾기 목록 |

**`recipeGeneratorProvider` 상태 흐름:**

```
[idle]
  │ generate() 호출
  ▼
[loading]  ← 로딩 Lottie 표시
  │ 성공
  ▼
[data: List<Recipe>]  ← RecipeCard 목록 표시
  │ 실패
  ▼
[error: AppError]  ← 에러 카드 표시
```

---

## 5. Bridge 설계 (Gemini API + 캐시)

### 5.1. GeminiService (`lib/services/gemini_service.dart`)

```dart
/// Gemini 1.5 Pro API 래퍼.
/// CLAUDE.md §2.3: 모델 — Gemini 1.5 Pro
abstract class GeminiService {
  Future<Result<String, AppError>> generate(String prompt);
}
```

- **모델:** `gemini-1.5-pro` (via `google_generative_ai` 패키지 또는 직접 REST)
- **Temperature:** `0.7` (창의적이되 구조를 준수)
- **maxOutputTokens:** `2048`
- **응답 형식:** JSON only (`responseMimeType: 'application/json'`)

### 5.2. PromptBuilder (`lib/services/prompt_builder.dart`)

**시스템 프롬프트 (고정):**

```
당신은 전문 요리사 AI입니다.
주어진 재료로 만들 수 있는 레시피를 정확한 JSON 형식으로만 응답하세요.
자연어 설명 없이 순수 JSON 배열만 출력하세요.

레시피는 반드시 아래 구조를 따라야 합니다:
- steps: 반드시 7단계 (prep→heat→base→main→season→finish→plate)
- recipe_type: main|side|soup|dessert|snack|drink|sauce 중 하나
- flavor_profile: 각 0~5 정수값
- science_note: 마이야르 반응, 유화, 삼투압 등 조리 과학 설명 (1~2문장)
- 각 단계의 tip에 재료 대체 가능성을 반드시 포함하세요
```

**사용자 프롬프트 구성:**

```dart
String build(RecipeRequest request) => '''
보유 재료: ${_formatIngredients(request.ingredients)}
레시피 유형: ${request.recipeType?.name ?? '제한 없음'}
인분: ${request.servings}인분
난이도: ${request.difficulty?.name ?? '제한 없음'}
레시피 3개를 JSON 배열로 추천해 주세요.
''';
```

### 5.3. 캐시 키 전략

```dart
/// 재료 ID 정렬 해시 + recipe_type + servings → 캐시 조회 키
String buildCacheKey(RecipeRequest request) {
  final sortedIds = request.ingredients.map((i) => i.id).toList()..sort();
  final typeStr = request.recipeType?.name ?? 'any';
  return '${sortedIds.join('_')}_${typeStr}_${request.servings}';
}
```

- 동일 캐시 키 존재 시 → Isar 캐시 즉시 반환
- 캐시 유효기간: **7일** (이후 자동 만료 + 새로 생성)
- 캐시 용량: 최대 **50개** 레시피 (FIFO 방식 삭제)

### 5.4. 에러 핸들링 및 재시도

```dart
Future<Result<List<Recipe>, AppError>> _callGeminiWithRetry(
  String prompt, {
  int maxRetries = 2,
}) async {
  for (int attempt = 0; attempt <= maxRetries; attempt++) {
    final response = await geminiService.generate(prompt);
    final parsed = _parseRecipes(response);
    if (parsed != null) return Result.success(parsed);
    // JSON 파싱 실패 시 더 단순한 프롬프트로 재시도
    if (attempt < maxRetries) prompt = _simplifyPrompt(prompt);
  }
  return const Result.failure(AppError.parsing('레시피 생성 실패. 다시 시도해 주세요.'));
}
```

| 에러 상황 | 처리 |
|----------|------|
| JSON 파싱 실패 | 최대 2회 재시도 (단순화 프롬프트) |
| 네트워크 오류 | 로컬 캐시 반환 → "저장된 레시피입니다" 배너 |
| 빈 재고 | CTA 비활성 + "재고를 먼저 등록해 주세요" 안내 |
| 캐시 없음 + 오프라인 | 에러 UI + 재연결 유도 버튼 |
| AI 과도한 창의성 | `recipe_type` 미일치 시 다시 생성 요청 |

### 5.5. Isar 컬렉션 (`lib/repositories/impl/isar_recipe.dart`)

```dart
@collection
class IsarRecipe {
  Id id = Isar.autoIncrement;
  @Index(type: IndexType.value)
  late String recipeId;       // UUID
  late String cacheKey;       // 재료 해시 기반 캐시 키
  late String title;
  late String jsonPayload;    // 전체 Recipe JSON 직렬화
  @Index()
  late bool isFavorite;
  @Index()
  late DateTime cachedAt;
}
```

---

## 6. UI Requirements (Artisan)

> 타이포그래피 상세: `design_system.md §1.2.4` 레시피 화면 섹션 참조.
> 레이아웃 와이어프레임: `screen_layout.md §3.4~3.5` 참조.

### 6.1. 화면별 상세

#### 6.1.1. 레시피 추천 화면 (`/recipe`)

```
┌──────────────────────────────┐
│ AppBar: "레시피"  [❤️ 즐겨찾기] │
├──────────────────────────────┤
│ 📦 재료 선택 [모두 선택][해제]  │
│ ─ 🥬 채소 ──────────────────  │
│ [배추 500g✓] [양파✓] [대파✓]   │ ← IngredientChip (보유량 표시)
│ ─ 🥩 육류 ──────────────────  │
│ [소고기 300g✓]                │
│                               │
│ ▼ 옵션 (접이식 ExpansionTile)  │
│ ┌─────────────────────────┐  │
│ │ recipe_type [전체 ▼]     │  │
│ │ 난이도      [제한없음 ▼]  │  │
│ │ 인분        [2인분 ▼]    │  │
│ └─────────────────────────┘  │
│                               │
│ ┌─────────────────────────┐  │
│ │ [레시피 추천 받기 🍳]  CTA │  │ ← Filled Button, Primary
│ └─────────────────────────┘  │
│                               │
│ ── 로딩 상태 ──               │
│ [cooking Lottie 중앙 128dp]   │
│ "맛있는 레시피를 찾고 있어요" │
│                               │
│ ── 결과 상태 ──               │
│ [RecipeCard #1] ← 탭 시 상세  │
│ [RecipeCard #2]               │
│ [RecipeCard #3]               │
├──────────────────────────────┤
│ [홈] [재고] [레시피] [마이]    │
└──────────────────────────────┘
```

#### 6.1.2. 레시피 상세 화면 (`/recipe/:id`)

```
┌──────────────────────────────┐
│ AppBar: "소고기 배추 전골" [❤️] │
├──────────────────────────────┤
│ [이모지 Hero 128dp]           │ ← Hero 애니메이션 (from RecipeCard)
│ 🍲 SOUP  |  30분 · 보통 · 2인 │
│                               │
│ ── 🍽️ 맛 프로필 ──            │
│ [FlavorRadar 5축 차트]        │ ← 감칠맛·단맛·신맛·짠맛·매운맛
│                               │
│ ── 📋 재료 ──                 │
│ ✅ 소고기 300g                │ ← 보유
│ ✅ 배추 500g                  │
│ ⬜ 된장 2큰술  [대체 보기 →]   │ ← 미보유: 탭 시 대체 힌트
│                               │
│ ── 👨‍🍳 조리 순서 ──            │
│ ┌────────────────────────┐   │
│ │  1  prep 재료 손질       │   │ ← displayLarge "1"
│ │ [🖼 이미지]              │   │
│ │ 배추를 한 잎씩 떼어...   │   │ ← bodyLarge
│ │ 💡 배추 심지부터 떼면... │   │ ← Tip callout
│ ├────────────────────────┤   │
│ │  2  heat 불 세팅         │   │
│ │ [⏱ 2분 타이머 시작]      │   │ ← duration 있을 때
│ │ ...                     │   │
│ └────────────────────────┘   │
│ ── 🔬 과학 노트 ──            │
│ ┌────────────────────────┐   │
│ │ 마이야르 반응으로...     │   │ ← scienceNote callout 카드
│ └────────────────────────┘   │
└──────────────────────────────┘
```

### 6.2. 위젯 목록

| 위젯 | 위치 | 역할 |
|------|------|------|
| `IngredientChip` | `/recipe` | 재료 선택 토글 (보유량 표시) |
| `RecipeCard` | `/recipe` 결과 | 레시피 요약 카드 |
| `RecipeTypeBadge` | RecipeCard 내부 | recipe_type 라벨 (`labelSmall`) |
| `FlavorRadar` | `/recipe/:id` | 5축 맛 프로필 radar 차트 |
| `IngredientCheckList` | `/recipe/:id` | 보유(✅)/미보유(⬜) 재료 리스트 |
| `CookingStepItem` | `/recipe/:id` | 단계 번호(displayLarge) + 설명 + 타이머 |
| `StepTimer` | CookingStepItem 내부 | 인라인 카운트다운 (displayMedium) |
| `TipCallout` | CookingStepItem 내부 | 💡 Tip, 대체 재료 힌트 callout |
| `ScienceNoteCard` | `/recipe/:id` 하단 | 🔬 science_note callout 카드 |
| `RecipeLoadingState` | `/recipe` | Cooking Lottie + 로딩 메시지 |
| `RecipeErrorState` | `/recipe` | 에러 안내 + 재시도 버튼 |
| `SubstituteBottomSheet` | 미보유 재료 탭 | 대체 재료 힌트 바텀시트 |

### 6.3. 상호작용 및 애니메이션

| 이벤트 | 효과 | 타이밍 |
|--------|------|--------|
| CTA 탭 (레시피 추천) | `mediumImpact()` | 즉시 |
| 레시피 카드 등장 | 슬라이드업 stagger (150ms 간격) | 결과 도착 후 |
| RecipeCard → 상세 | Hero 애니메이션 (300ms) | 탭 즉시 |
| 즐겨찾기 토글 | ❤️ 스케일 팝 (1.0→1.3→1.0, 200ms) + `lightImpact()` | 탭 즉시 |
| 타이머 완료 | `vibrate()` + Lottie 완료 1회 | D+0s |
| 재료 칩 선택 | `selectionClick()` | 탭 즉시 |
| 조리 단계 스크롤 | Magnetic snapping (Design Creed §3) | 스크롤 중 |

### 6.4. 레시피 추천 화면 — IngredientChip 상세

```
[배추 500g ✓]  ← 선택됨: Primary 배경, onPrimary 텍스트, 체크 아이콘
[고수 30g]     ← 미선택: surfaceContainerHigh 배경
```

- 카테고리별로 그룹핑 (재고의 StorageLocation이 아닌 StockCategory 기준)
- 각 칩에 수량 표시 (예: "소고기 300g")
- 재료 0개 선택 시 CTA 버튼 비활성 (`FilledButton` disabled 상태)

### 6.5. 로딩 상태 카피

| 상태 | 메시지 (`bodyLarge`) |
|------|---------------------|
| 캐시 조회 중 | "저장된 레시피를 확인하고 있어요..." |
| AI 생성 중 | "맛있는 레시피를 찾고 있어요 🍳" |
| 파싱 중 | "재료를 정리하고 있어요..." |
| 재시도 | "조금 더 맛있게 다듬고 있어요 👨‍🍳" |

---

## 7. Edge Cases

| 상황 | 처리 |
|------|------|
| 재고 0개 | RecipeScreen에서 "재고를 먼저 등록해 주세요" + 재고 탭 이동 버튼 |
| 재료 1개만 선택 | 허용. Gemini가 단일 재료 레시피 생성 (예: "계란 후라이") |
| AI가 존재하지 않는 재료 포함 | `IngredientCheckList`에서 ⬜ 처리 (미보유로 표시) |
| 동일 recipe_type 요청 연속 | 캐시 히트 → 즉시 반환, "저장된 레시피" 배너 |
| Gemini 응답 파싱 오류 2회 연속 | 에러 UI + "잠시 후 다시 시도해 주세요" |
| JSON steps 7개 미만 | 파싱 실패로 처리 → 재시도 (AC-3, AC-4) |
| science_note 없음 | 🔬 카드 표시 안 함 (AC-12) |
| 매우 긴 레시피명 | `headlineLarge` 2줄 허용, 3줄 이상은 ellipsis |
| 타이머 백그라운드 전환 | 알림(notification) 발송 (Phase 1.4 이후) |

---

## 8. 선행 조건 및 의존성

```
Phase 1.0
└── StockItem 모델, Isar 인프라, StorageLocation/StockCategory enum
    → RecipeRequest에서 selectedIngredients로 사용

Phase 1.1 (본 문서)
├── Architect: Recipe, RecipeStep, FlavorProfile 모델 → RecipeRepository 인터페이스
├── Bridge:    GeminiService → PromptBuilder → RecipeGenerationService
│              → IsarRecipeRepository (캐시)
└── Artisan:   RecipeScreen → RecipeDetailScreen → 모든 위젯

Phase 2.0+ (의존 없음, 향후 확장)
└── Server Cache 계층 추가 (RecipeRepository 인터페이스 변경 없이 구현체만 교체)
```

---

## 9. 파일 구조

```
app/lib/
├── models/
│   ├── recipe.dart              # Architect
│   ├── recipe_step.dart         # Architect
│   ├── recipe_ingredient.dart   # Architect
│   ├── flavor_profile.dart      # Architect
│   ├── recipe_type.dart         # Architect (enum)
│   ├── cooking_phase.dart       # Architect (enum)
│   ├── difficulty_level.dart    # Architect (enum)
│   └── recipe_request.dart      # Architect
│
├── repositories/
│   ├── recipe_repository.dart              # Architect (interface)
│   └── impl/
│       ├── isar_recipe.dart                # Bridge (Isar collection)
│       └── isar_recipe_repository.dart     # Bridge (implementation)
│
├── providers/
│   └── recipe_providers.dart               # Architect
│
├── services/
│   ├── gemini_service.dart                 # Bridge (API 래퍼)
│   ├── prompt_builder.dart                 # Bridge (프롬프트 빌더)
│   └── recipe_generation_service.dart      # Bridge (파싱·캐시 오케스트레이터)
│
├── views/
│   └── recipe/
│       ├── recipe_screen.dart              # Artisan (재료 선택 + 결과)
│       └── recipe_detail_screen.dart       # Artisan (조리 가이드)
│
└── widgets/
    └── recipe/
        ├── ingredient_chip.dart            # Artisan
        ├── recipe_card.dart                # Artisan
        ├── recipe_type_badge.dart          # Artisan
        ├── flavor_radar.dart               # Artisan (CustomPainter)
        ├── ingredient_check_list.dart      # Artisan
        ├── cooking_step_item.dart          # Artisan
        ├── step_timer.dart                 # Artisan
        ├── tip_callout.dart                # Artisan
        ├── science_note_card.dart          # Artisan
        ├── recipe_loading_state.dart       # Artisan
        ├── recipe_error_state.dart         # Artisan
        └── substitute_bottom_sheet.dart    # Artisan
```
