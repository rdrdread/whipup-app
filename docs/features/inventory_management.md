# Inventory Management (재고 관리)

> **Phase:** 1.0
> **참조 에이전트:** Architect (모델/로직), Artisan (UI), Bridge (DB 인프라)
> **상위 문서:** `roadmap.md §2`, `product_map.md §3`

---

## 1. Feature Summary

사용자가 냉장고·팬트리의 식재료를 등록·수정·삭제하고, 유통기한을 추적하여 폐기를 줄이는 핵심 기능.
WhipUp의 모든 후속 기능(레시피 추천, OCR, 음성 입력)이 이 재고 데이터에 의존한다.

---

## 2. User Stories

### US-1: 재료 수동 등록
> "냉장고에 새로 넣은 재료를 앱에 등록하고 싶다."

- **Given:** 사용자가 재고 목록 화면에서 FAB(+)을 탭
- **When:** 재료명, 카테고리, 수량, 단위를 입력하고 [저장] 탭
- **Then:** 재료가 Isar DB에 저장되고, 목록에 즉시 나타남
- **And:** `HapticFeedback.lightImpact()` 재생

### US-2: 재료 수정
> "수량이 바뀌었거나 정보를 잘못 입력했다."

- **Given:** 재고 목록에서 재료 카드 탭
- **When:** 수정 화면에서 필드를 변경하고 [저장] 탭
- **Then:** 변경사항이 DB에 반영되고, 목록이 갱신됨

### US-3: 재료 삭제
> "다 쓴 재료를 목록에서 지우고 싶다."

- **Given:** 재고 목록에서 재료 카드를 왼쪽으로 스와이프
- **When:** 삭제 확인 영역이 나타나고 스와이프 완료
- **Then:** `HapticFeedback.heavyImpact()` + 재료 삭제
- **And:** Snackbar로 "되돌리기" 옵션 제공 (5초)

### US-4: 카테고리 필터
> "채소만 보고 싶다."

- **Given:** 재고 목록 상단의 카테고리 칩 영역
- **When:** [🥬 채소] 칩을 탭
- **Then:** 해당 카테고리 재료만 필터링하여 표시
- **And:** 다시 탭하면 필터 해제

### US-5: 정렬
> "유통기한 임박한 순서로 보고 싶다."

- **Given:** 재고 목록의 정렬 드롭다운
- **When:** [유통기한순]을 선택
- **Then:** 유통기한이 가까운 재료가 상단에 표시

### US-6: 서브 카테고리 선택 및 단위 자동 추천
> "돼지고기 목살을 선택하면 단위가 자동으로 g으로 설정되면 좋겠다."

- **Given:** 재료 추가 화면에서 카테고리(예: 육류)를 선택
- **When:** 서브 카테고리(돼지고기) → 부위(목살)를 순차 선택
- **Then:** 재료명이 "돼지고기 (목살)"로 자동 입력됨
- **And:** 단위가 해당 재료의 기본 단위(g)로 실시간 설정됨
- **And:** 단위 필드 옆에 "자동" 라벨이 표시되며, 사용자가 수동 변경 가능

> **서브 카테고리 맵핑:** `product_map.md §3.1` StockCategory 서브 카테고리 예시 참조.
> **기본 단위 로직:** 카테고리 + 서브 카테고리 조합에 따라 기본 단위를 결정 (예: 육류 → g, 과일 → 개, 액체류 → ml).

### US-7: 유통기한 알림
> "유통기한 임박한 재료를 놓치고 싶지 않다."

- **Given:** 유통기한이 3일 이내인 재료가 존재
- **When:** 홈 화면 진입
- **Then:** "유통기한 임박" 섹션에 해당 재료 표시 (warningAmber 색상)
- **And:** 유통기한 초과 시 dangerRed 색상으로 변경

---

## 3. Acceptance Criteria

| # | 기준 | 검증 방법 |
|---|------|----------|
| AC-1 | 재료 CRUD(생성·조회·수정·삭제)가 정상 동작 | Unit Test + UI 확인 |
| AC-2 | Isar 영속화: 앱 재시작 후 데이터 유지 | 수동 테스트 |
| AC-3 | 카테고리 필터 동작 (10개 카테고리) | Unit Test |
| AC-4 | 정렬: 이름순, 유통기한순, 등록일순 | Unit Test |
| AC-5 | 유통기한 색상 분류 (fresh/warning/danger) | Unit Test |
| AC-6 | 빈 상태: 재고 0개일 때 empty_fridge Lottie 표시 | UI 확인 |
| AC-7 | 스와이프 삭제 + 되돌리기 동작 | UI 확인 |
| AC-8 | 폼 유효성 검사: 필수 필드 미입력 시 에러 표시 | UI 확인 |
| AC-9 | Light/Dark 테마에서 모든 색상 정상 표시 | UI 확인 |
| AC-10 | 서브 카테고리 선택 시 재료명 자동 입력 | UI 확인 |
| AC-11 | 서브 카테고리 선택 시 단위 자동 설정 (예: 육류→g, 과일→개) | Unit Test |
| AC-12 | 자동 설정된 단위를 사용자가 수동 변경 가능 | UI 확인 |

---

## 4. Data Requirements

### 4.1. StockItem 필드

→ `product_map.md §3.1` 참조

### 4.2. StockCategory enum

→ `product_map.md §3.1` StockCategory enum 참조

### 4.3. StockFilter

| Field | Type | 설명 |
|-------|------|------|
| `category` | StockCategory? | null이면 전체 |
| `sortBy` | SortType (enum) | `name`, `expiryDate`, `addedAt` |
| `sortAscending` | bool | 오름차순 여부 |

### 4.4. 유통기한 상태 분류

| 조건 | 상태 | 색상 Token |
|------|------|-----------|
| 유통기한 없음 또는 3일 초과 남음 | `fresh` | `freshGreen` |
| 유통기한 3일 이내 | `warning` | `warningAmber` |
| 유통기한 초과 | `danger` | `dangerRed` |

---

## 5. UI Requirements

### 5.1. 화면별 상세

→ `screen_layout.md §3.1~3.3` 참조 (홈, 재고 목록, 재고 추가/수정)

### 5.2. 위젯 목록

| 위젯 | 사용 화면 | 스타일 참조 |
|------|----------|-----------|
| `IngredientCard` | 재고 목록, 홈 | `design_system.md §6.1` |
| `CategoryChip` | 재고 목록 필터 | `design_system.md §6.5` |
| `ExpiryBadge` | IngredientCard 내부 | `design_system.md §6.5` |
| `EmptyStateWidget` | 재고 목록 (0개) | `design_system.md §6.5` |

---

## 6. Edge Cases

| 상황 | 처리 |
|------|------|
| 동일 재료명 중복 등록 | 허용 (수량이 다를 수 있음) |
| 유통기한 미입력 | `expiryDate = null`, fresh 상태로 표시 |
| 수량 0 | 허용 (삭제 권유 Snackbar 표시) |
| 매우 긴 재료명 | 1줄 말줄임 (ellipsis) |
| 재고 100개 이상 | 성능 테스트 필요 (Isar 인덱스 활용) |
