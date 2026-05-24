# Product Map

> **참조 규칙:** AI 에이전트는 레시피 JSON 생성 시 반드시 이 문서의 Section 2를 참조해야 한다. (CLAUDE.md §3.3)

---

## 1. Feature Overview (Phase 로드맵)

| Phase | Feature | Status |
|-------|---------|--------|
| 1.0 | 재고 관리 (수동 입력) | 🔲 TODO |
| 1.1 | AI 레시피 추천 (Gemini) | 🔲 TODO |
| 1.2 | 카메라 OCR 영수증 인식 | 🔲 TODO |
| 1.3 | 음성 재료 입력 | 🔲 TODO |
| 2.0 | 백엔드 연동 (FastAPI + pgvector) | 🔲 TODO |
| 2.1 | 레시피 벡터 캐시 | 🔲 TODO |
| 2.6 | Weekly Column 발행 | 🔲 TODO |

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

## 3. Stock (재고) Data Model

> Isar DB에 저장되는 재고 엔티티 기본 필드.

| Field | Type | 설명 |
|-------|------|------|
| `id` | int | Isar 자동 ID |
| `name` | String | 재료명 |
| `category` | String | 카테고리 (채소/육류/유제품 등) |
| `quantity` | double | 수량 |
| `unit` | String | 단위 (g/ml/개) |
| `expiryDate` | DateTime? | 유통기한 |
| `addedAt` | DateTime | 등록일 |
