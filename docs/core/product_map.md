# Product Map

> **참조 에이전트:** Architect (정본), Bridge (정본)
> Architect는 모델과 Repository 설계 시, Bridge는 API 계약과 데이터 파싱 시 이 문서를 최우선 참조한다.

---

## 1. Data Architecture Overview

### 1.1. 레이어 구조

```
┌─────────────────────────────────────────────┐
│  Artisan Layer (UI)                         │
│  lib/views, lib/widgets, lib/theme          │
│  ConsumerWidget → ref.watch(provider)       │
├─────────────────────────────────────────────┤
│  Architect Layer (Logic)                    │
│  lib/providers, lib/repositories, lib/models│
│  Riverpod Provider → Repository → Model    │
├─────────────────────────────────────────────┤
│  Bridge Layer (External)                    │
│  lib/services, backend/                     │
│  Dio/Retrofit, Gemini API, Isar impl        │
└─────────────────────────────────────────────┘
```

### 1.2. 의존 방향

```
Artisan(UI) ──→ Architect(Logic) ──→ Bridge(External)
              ref.watch()           Repository impl
```

- UI는 Provider만 소비하고 Repository/Service에 직접 접근하지 않음.
- Provider는 Repository 인터페이스에 의존하며, 구현체는 Bridge가 주입.
- 모든 비동기 결과는 `Result<T, E>` 패턴으로 래핑.

---

## 2. Atomic Recipe Structure (7단계 조리 구조)

> **CLAUDE.md §3.3:** AI가 생성하는 모든 레시피 JSON은 아래 7단계 구조와 `recipe_type` 필드를 **반드시** 포함해야 한다.

### 2.1. Recipe JSON Schema

```json
{
  "id": "string (UUID)",
  "title": "string",
  "description": "string",
  "recipe_type": "main | side | soup | dessert | snack | drink | sauce",
  "servings": "integer",
  "cooking_time_minutes": "integer",
  "difficulty": "easy | medium | hard",
  "ingredients": [
    {
      "name": "string",
      "amount": "string",
      "unit": "string",
      "is_optional": "boolean"
    }
  ],
  "steps": [
    {
      "step_number": "integer (1~7)",
      "phase": "prep | heat | base | main | season | finish | plate",
      "description": "string",
      "duration_seconds": "integer | null",
      "tip": "string | null"
    }
  ],
  "tags": ["string"],
  "flavor_profile": {
    "umami": "0~5",
    "sweet": "0~5",
    "sour": "0~5",
    "salty": "0~5",
    "spicy": "0~5"
  },
  "science_note": "string | null",
  "sources": ["string"]
}
```

### 2.2. Step Phase 정의 (7단계)

| # | Phase | 설명 |
|---|-------|------|
| 1 | `prep` | 재료 손질 (세척, 절단, 계량) |
| 2 | `heat` | 기름·불 세팅 (팬 예열, 물 끓이기) |
| 3 | `base` | 베이스 조리 (향신료, 볶음 시작) |
| 4 | `main` | 메인 재료 투입·조리 |
| 5 | `season` | 간 맞추기 (소금, 간장, 설탕 등) |
| 6 | `finish` | 마무리 (불 끄기, 버터 마운팅 등) |
| 7 | `plate` | 플레이팅 및 가니시 |

### 2.3. recipe_type 정의

| Type | 설명 |
|------|------|
| `main` | 주요리 |
| `side` | 반찬 |
| `soup` | 국·찌개·탕 |
| `dessert` | 후식·디저트 |
| `snack` | 간식 |
| `drink` | 음료·주스 |
| `sauce` | 소스·드레싱 |

---

## 3. Data Models (Freezed)

> Architect가 `lib/models/`에 Freezed로 정의. 모든 모델은 `fromJson`/`toJson` 팩토리를 포함한다.

### 3.1. Stock (재고)

| Field | Type | 설명 |
|-------|------|------|
| `id` | int | Isar 자동 ID |
| `name` | String | 재료명 |
| `category` | StockCategory (enum) | 카테고리 |
| `storageLocation` | StorageLocation (enum) | 보관 위치 |
| `quantity` | double | 수량 |
| `unit` | String | 단위 (g/ml/개) |
| `expiryDate` | DateTime? | 유통기한 |
| `addedAt` | DateTime | 등록일 |

**StorageLocation enum:**

| 값 | 한글 | 아이콘 | 설명 |
|----|------|--------|------|
| `fridge` | 냉장고 | 🧊 | 냉장·냉동 보관 식재료 |
| `pantry` | 팬트리 | 📦 | 상온 보관 (쌀, 통조림, 건조식품 등) |
| `drawer` | 서랍 | 🗄️ | 양념장, 소스류, 기타 소모품 |

**StockCategory enum:**

| 값 | 한글 | 이모지 |
|----|------|--------|
| `vegetable` | 채소 | 🥬 |
| `fruit` | 과일 | 🍎 |
| `meat` | 육류 | 🥩 |
| `seafood` | 해산물 | 🐟 |
| `dairy` | 유제품 | 🧀 |
| `grain` | 곡물 | 🌾 |
| `seasoning` | 양념/소스 | 🧂 |
| `beverage` | 음료 | 🥤 |
| `frozen` | 냉동식품 | 🧊 |
| `other` | 기타 | 🍽️ |

> 이모지 매핑은 `brand-assets §4.4`와 동기화.

### 3.2. Recipe (레시피)

§2.1 JSON Schema를 Freezed 모델로 1:1 매핑. 하위 모델:
- `RecipeStep` — step_number, phase (CookingPhase enum), description, duration_seconds, tip
- `Ingredient` — name, amount, unit, isOptional
- `FlavorProfile` — umami, sweet, sour, salty, spicy (int 0~5)
- `RecipeType` enum — main, side, soup, dessert, snack, drink, sauce
- `CookingPhase` enum — prep, heat, base, main, season, finish, plate

### 3.3. Column (칼럼)

| Field | Type | 설명 |
|-------|------|------|
| `id` | String | 고유 ID (col_001 등) |
| `title` | String | 제목 |
| `subtitle` | String | 부제 |
| `body` | String | 본문 (플레인 텍스트) |
| `category` | ColumnCategory (enum) | 카테고리 |
| `tags` | List\<String\> | 태그 목록 |
| `sources` | List\<Source\> | 출처 목록 |
| `thumbnailEmoji` | String | 대표 이모지 |
| `publishedAt` | DateTime | 발행일 |
| `readingTimeMinutes` | int | 읽기 예상 시간 |

**ColumnCategory enum:** `ingredient`, `science`, `culture`, `safety`, `seasonal`

---

## 4. Repository Interfaces (Architect)

> Architect가 정의하는 추상 인터페이스. Bridge가 구현체를 제공한다.

### 4.1. StockRepository

```dart
abstract class StockRepository {
  Future<Result<List<StockItem>, StockError>> getAll();
  Future<Result<StockItem, StockError>> getById(int id);
  Future<Result<void, StockError>> add(StockItem item);
  Future<Result<void, StockError>> update(StockItem item);
  Future<Result<void, StockError>> delete(int id);
  Future<Result<List<StockItem>, StockError>> getExpiringSoon(int days);
  Stream<List<StockItem>> watchAll();
}
```

### 4.2. RecipeRepository

```dart
abstract class RecipeRepository {
  Future<Result<Recipe, RecipeError>> generateFromStock(List<StockItem> items);
  Future<Result<List<Recipe>, RecipeError>> getCached();
  Future<Result<void, RecipeError>> saveToCache(Recipe recipe);
  Future<Result<void, RecipeError>> favorite(String recipeId);
}
```

### 4.3. ColumnRepository

```dart
abstract class ColumnRepository {
  Future<Result<List<Column>, ColumnError>> getAll();
  Future<Result<Column, ColumnError>> getById(String id);
}
```

---

## 5. Provider Architecture (Architect)

> 모든 Provider는 `@riverpod` 어노테이션 사용 (riverpod_generator).

### 5.1. Stock Providers

| Provider | 타입 | 역할 |
|----------|------|------|
| `stockListProvider` | `AsyncNotifier<List<StockItem>>` | 전체 재고 CRUD + 실시간 감시 |
| `stockFilterProvider` | `Notifier<StockFilter>` | 필터/정렬 상태 |
| `filteredStockProvider` | `Provider<AsyncValue<List<StockItem>>>` | 필터 적용 파생 목록 |
| `expiringStockProvider` | `FutureProvider<List<StockItem>>` | 유통기한 임박 목록 |

### 5.2. Recipe Providers

| Provider | 타입 | 역할 |
|----------|------|------|
| `recipeGeneratorProvider` | `AsyncNotifier<Recipe?>` | AI 레시피 생성 요청·결과 |
| `recipeCacheProvider` | `AsyncNotifier<List<Recipe>>` | 로컬 캐시 목록 |
| `favoriteRecipesProvider` | `AsyncNotifier<List<Recipe>>` | 즐겨찾기 |
| `selectedIngredientsProvider` | `Notifier<List<StockItem>>` | 레시피 요청용 선택 재료 |

### 5.3. Column Providers

| Provider | 타입 | 역할 |
|----------|------|------|
| `columnListProvider` | `AsyncNotifier<List<Column>>` | 칼럼 목록 |
| `columnDetailProvider` | `FutureProvider.family<Column, String>` | 칼럼 상세 (ID 기준) |

---

## 6. Data Flow (Bridge)

### 6.1. 레시피 생성 플로우

```
[사용자: 재료 선택]
       │
       ▼
[Architect: selectedIngredientsProvider]
       │
       ▼
[Architect: recipeGeneratorProvider.generate()]
       │
       ▼
[Bridge: RecipeRepository.generateFromStock()]
       │
       ├── 1순위: Isar Local Cache 조회 → Hit → 반환
       │
       ├── 2순위: Server Cache 조회 (Phase 2.0+) → Hit → 반환 + Local 저장
       │
       └── 3순위: GeminiService.generate()
                    │
                    ├── PromptBuilder: 재료 → 구조화 프롬프트
                    ├── Gemini API 호출 (JSON only)
                    ├── Recipe.fromJson() 역직렬화
                    └── Local Cache 저장 → 반환
```

### 6.2. 재고 등록 플로우

```
[수동 입력]  [OCR 영수증]  [음성 입력]
     │            │            │
     └──────┬─────┘──────┬─────┘
            ▼            ▼
     [StockItem 생성 / 확인 UI]
            │
            ▼
     [StockRepository.add()]
            │
            ▼
     [Isar DB 저장 → watchAll() 스트림 갱신]
```

### 6.3. Caching Priority (CLAUDE.md §3.3)

```
1. Local (Isar)     → 가장 빠름, 오프라인 가능
2. Server Cache     → Phase 2.0+, pgvector 유사도 검색
3. AI (Gemini)      → 최후의 수단, 비용·지연 발생
```

---

## 7. External API Contract (Bridge)

### 7.1. Gemini API

| 항목 | 값 |
|------|-----|
| **모델** | `gemini-1.5-pro` |
| **Temperature** | `0.7` |
| **Max Tokens** | `4096` |
| **Timeout** | `30초` |
| **재시도** | 최대 2회 (exponential backoff: 2s, 4s) |
| **API Key 저장** | `secure_storage` (하드코딩 금지) |

### 7.2. Backend API (Phase 2.0+)

| Method | Endpoint | 설명 |
|--------|----------|------|
| `POST` | `/api/v1/recipes/generate` | 재료 기반 레시피 생성 |
| `GET` | `/api/v1/recipes/similar` | pgvector 유사 레시피 검색 |
| `GET` | `/api/v1/recipes/cached` | 서버 캐시 레시피 조회 |
| `POST` | `/api/v1/stock/sync` | 재고 데이터 서버 동기화 |
| `GET` | `/api/v1/columns` | 칼럼 목록 조회 |
| `GET` | `/api/v1/columns/:id` | 칼럼 상세 조회 |
| `POST` | `/api/v1/columns/:id/personalize` | 개인화 헤드라인 생성 |

### 7.3. 에러 핸들링 원칙

| 에러 유형 | 처리 |
|----------|------|
| 네트워크 끊김 | 캐시 폴백 + 오프라인 안내 |
| API Rate Limit (429) | Retry-After 대기 후 재시도 |
| JSON 파싱 실패 | 1회 재시도 후 에러 반환 |
| 필수 필드 누락 | 에러 반환 (AI 응답 로그) |
| API Key 만료 (401) | 사용자에게 키 재입력 안내 |
| 서버 에러 (5xx) | 재시도 2회 후 에러 반환 |

---

## 8. Code Structure

```
app/lib/
├── models/                    # Freezed 모델 (Architect)
│   ├── stock_item.dart
│   ├── stock_category.dart
│   ├── recipe.dart
│   ├── recipe_step.dart
│   ├── ingredient.dart
│   ├── flavor_profile.dart
│   ├── recipe_type.dart
│   ├── cooking_phase.dart
│   ├── column.dart
│   └── column_category.dart
├── repositories/              # 인터페이스 + 구현 (Architect + Bridge)
│   ├── stock_repository.dart
│   ├── recipe_repository.dart
│   ├── column_repository.dart
│   └── impl/
│       ├── isar_stock_repository.dart
│       ├── local_recipe_repository.dart
│       └── local_column_repository.dart
├── providers/                 # Riverpod Provider (Architect)
│   ├── stock_providers.dart
│   ├── recipe_providers.dart
│   └── column_providers.dart
├── services/                  # 외부 연동 (Bridge)
│   ├── gemini_service.dart
│   ├── recipe_generation_service.dart
│   ├── prompt_builder.dart
│   ├── ocr_service.dart
│   └── voice_input_service.dart
└── core/                      # 공용 유틸리티 (Architect)
    ├── result.dart
    └── errors.dart
```
