# Architect Agent Plan

> **페르소나:** 원칙주의적이고 깐깐한 수석 소프트웨어 엔지니어. "기능보다 안정성."
> **권한 범위:** `lib/models`, `lib/repositories`, `lib/providers` (쓰기) / 나머지 (읽기 전용)
> **자문:** "이 로직이 Clean Architecture의 레이어 원칙을 준수하는가?"

---

## 1. 핵심 원칙

1. **Interface-First:** Freezed 모델과 추상 인터페이스를 먼저 정의한 뒤 구현. Artisan/Bridge가 의존할 계약을 선제 확보.
2. **Dependency Direction:** `Artisan(UI) → Architect(Logic) → Bridge(External)` 단방향 엄수.
3. **Immutable State:** 모든 데이터 모델은 Freezed로 불변 객체화. `copyWith`로만 상태 변경.
4. **Result Pattern:** 모든 비동기 결과는 `Result<T, E>` 패턴으로 래핑. 암묵적 예외 전파 금지.
5. **Type-Safe Provider:** 모든 Provider는 `riverpod_generator` 사용. 수동 Provider 선언 금지.

---

## 2. Phase별 산출물

### Phase 1.0 — 재고 관리 (Stock Management)

#### 2.1. Freezed 모델

| 모델 | 파일 | 핵심 필드 | 참조 |
|------|------|----------|------|
| `StockItem` | `lib/models/stock_item.dart` | id, name, category, quantity, unit, expiryDate, addedAt | `product_map.md §3` |
| `StockCategory` | `lib/models/stock_category.dart` | enum: vegetable, fruit, meat, seafood, dairy, grain, seasoning, beverage, frozen, other | `brand-assets §4.4` |
| `StockFilter` | `lib/models/stock_filter.dart` | category, sortBy, expiryRange | — |

#### 2.2. Repository 인터페이스

```
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

#### 2.3. Provider 설계

| Provider | 타입 | 역할 |
|----------|------|------|
| `stockListProvider` | `AsyncNotifier<List<StockItem>>` | 전체 재고 CRUD 및 실시간 감시 |
| `stockFilterProvider` | `Notifier<StockFilter>` | 필터/정렬 상태 관리 |
| `filteredStockProvider` | `Provider<AsyncValue<List<StockItem>>>` | 필터 적용된 재고 목록 (파생) |
| `expiringStockProvider` | `FutureProvider<List<StockItem>>` | 유통기한 임박 목록 |

#### 2.4. Isar 스키마

- `StockItemCollection`: Isar 컬렉션으로 `StockItem` 영속화
- 인덱스: `name` (전문 검색), `category`, `expiryDate` (범위 쿼리)
- Freezed ↔ Isar 변환 매퍼 별도 분리 (`lib/repositories/mappers/`)

#### 2.5. Unit Test 필수 범위

- [ ] StockItem 생성/유효성 검증
- [ ] 재고 CRUD 전체 시나리오
- [ ] 유통기한 임박 필터 로직
- [ ] 수량 차감 시 0 미만 방지
- [ ] StockFilter 적용 정렬 검증

---

### Phase 1.1 — AI 레시피 추천

#### 2.6. Freezed 모델

| 모델 | 파일 | 참조 |
|------|------|------|
| `Recipe` | `lib/models/recipe.dart` | `product_map.md §2.1` JSON 스키마 완전 반영 |
| `RecipeStep` | `lib/models/recipe_step.dart` | 7단계 phase enum 포함 |
| `Ingredient` | `lib/models/ingredient.dart` | name, amount, unit, isOptional |
| `FlavorProfile` | `lib/models/flavor_profile.dart` | umami, sweet, sour, salty, spicy (0~5) |
| `RecipeType` | `lib/models/recipe_type.dart` | enum: main, side, soup, dessert, snack, drink, sauce |
| `CookingPhase` | `lib/models/cooking_phase.dart` | enum: prep, heat, base, main, season, finish, plate |
| `RecipeRequest` | `lib/models/recipe_request.dart` | 재고 기반 추천 요청 DTO |

#### 2.7. Repository 인터페이스

```
abstract class RecipeRepository {
  Future<Result<Recipe, RecipeError>> generateFromStock(List<StockItem> items);
  Future<Result<List<Recipe>, RecipeError>> getCached();
  Future<Result<void, RecipeError>> saveToCache(Recipe recipe);
  Future<Result<void, RecipeError>> favorite(String recipeId);
}
```

#### 2.8. Caching Priority 구현

```
캐시 계층:
1. Isar Local Cache → Hit? → 반환
2. Server Cache (Phase 2.0+) → Hit? → 반환 + Local 저장
3. Gemini AI 생성 → 반환 + Local 저장 (+ Server 저장)
```

#### 2.9. Provider 설계

| Provider | 타입 | 역할 |
|----------|------|------|
| `recipeGeneratorProvider` | `AsyncNotifier<Recipe?>` | AI 레시피 생성 요청·결과 관리 |
| `recipeCacheProvider` | `AsyncNotifier<List<Recipe>>` | 로컬 캐시 레시피 목록 |
| `favoriteRecipesProvider` | `AsyncNotifier<List<Recipe>>` | 즐겨찾기 레시피 |
| `selectedIngredientsProvider` | `Notifier<List<StockItem>>` | 선택된 재료 목록 (레시피 요청용) |

---

### Phase 2.6 — Weekly Column

#### 2.10. Freezed 모델

| 모델 | 파일 | 역할 |
|------|------|------|
| `Column` | `lib/models/column.dart` | id, title, subtitle, body, category, tags, sources, publishedAt, thumbnailEmoji |
| `ColumnCategory` | `lib/models/column_category.dart` | enum: ingredient, science, culture, safety, seasonal |

---

## 3. 폴더 구조

```
app/lib/
├── models/                    # Freezed 모델 (Architect 전용)
│   ├── stock_item.dart
│   ├── stock_item.freezed.dart
│   ├── stock_item.g.dart
│   ├── recipe.dart
│   ├── recipe_step.dart
│   ├── ingredient.dart
│   ├── flavor_profile.dart
│   ├── recipe_type.dart
│   ├── cooking_phase.dart
│   ├── recipe_request.dart
│   ├── column.dart
│   └── column_category.dart
├── repositories/              # 추상 인터페이스 + 구현 (Architect 전용)
│   ├── stock_repository.dart
│   ├── recipe_repository.dart
│   ├── column_repository.dart
│   ├── impl/
│   │   ├── isar_stock_repository.dart
│   │   ├── local_recipe_repository.dart
│   │   └── local_column_repository.dart
│   └── mappers/
│       ├── stock_mapper.dart
│       └── recipe_mapper.dart
├── providers/                 # Riverpod Provider (Architect 전용)
│   ├── stock_providers.dart
│   ├── recipe_providers.dart
│   └── column_providers.dart
└── core/                      # 공용 유틸리티
    ├── result.dart            # Result<T, E> 패턴
    └── errors.dart            # 도메인 에러 타입
```

---

## 4. 타 에이전트와의 계약

### Artisan에게 제공

- 모든 Provider의 `AsyncValue<T>` 타입 반환 보장
- UI에서 `when(data:, loading:, error:)` 패턴으로 소비 가능
- StockCategory enum → `brand-assets §4.4` 이모지 매핑과 1:1 대응

### Bridge에게 제공

- `RecipeRequest` DTO → Bridge가 Gemini 프롬프트 구성에 사용
- `Recipe` Freezed 모델 → Bridge가 AI 응답 JSON을 역직렬화할 타겟
- Repository 추상 인터페이스 → Bridge가 서버 통신 구현체 주입

### Editor에게 제공

- `Column` Freezed 모델 스키마 → Editor가 `columns.json` 작성 시 준수
- `ColumnCategory` enum → Editor가 콘텐츠 카테고리 분류에 사용

---

## 5. Verification Checklist

매 PR 생성 전 자가 검증:

- [ ] 모든 모델에 `@freezed` 어노테이션과 `fromJson`/`toJson` 팩토리 존재
- [ ] `dart run build_runner build --delete-conflicting-outputs` 성공
- [ ] Repository 인터페이스가 `Result` 패턴 반환
- [ ] Provider에 `@riverpod` 어노테이션 사용 (수동 선언 없음)
- [ ] `lib/views`, `lib/widgets`, `lib/services` 파일 수정 없음 (Read-only 영역)
- [ ] 핵심 로직(차감, 해싱, 필터)에 Unit Test 동반
- [ ] `product_map.md §2`의 7단계 구조와 recipe_type 완전 반영
