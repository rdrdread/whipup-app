# Roadmap

> **참조 에이전트:** 전원 필수
> 개발 단계를 세분화하고, 각 Phase에서 에이전트별 산출물과 선행 조건을 정의한다.

---

## 1. Phase Overview

| Phase | 기능 | 핵심 가치 | Status |
|-------|------|----------|--------|
| **1.0** | 재고 관리 (수동 입력) | 냉장고 속 재료를 한눈에 | ✅ 완료 |
| **1.1** | AI 레시피 추천 | 재료 → 근사한 한 끼 | ✅ 완료 |
| **1.2** | 카메라 OCR 영수증 인식 | 영수증 찍으면 재고 자동 등록 | ✅ 완료 |
| **1.3** | 음성 재료 입력 | 말로 재료 추가 | ✅ 완료 |
| **1.4** | 리워드 시스템 | 요리의 즐거움을 보상으로 | ✅ 완료 |
| **1.5** | 영상 URL 레시피 추출 | YouTube·영상 링크로 레시피 뚝딱 | ✅ 완료 |
| **2.0** | 백엔드 연동 (FastAPI) | 서버 기반 확장 | ✅ 완료 |
| **2.1** | 레시피 벡터 캐시 (pgvector) | 유사 레시피 재활용 | ✅ 완료 |
| **2.6** | Weekly Column 발행 | 요리 지식 콘텐츠 | ✅ 완료 |

---

## 2. Phase 1.0 — 재고 관리

> **목표:** 사용자가 냉장고 재료를 수동으로 등록·관리할 수 있는 기본 기능 완성.
> **Feature Doc:** `docs/features/inventory_management.md`

### 2.1. 에이전트별 산출물

| 에이전트 | 산출물 | 파일 |
|---------|--------|------|
| **Architect** | StockItem Freezed 모델 + StockCategory enum | `lib/models/` |
| | StockRepository 인터페이스 | `lib/repositories/` |
| | Isar 스키마 + StockRepository 구현체 | `lib/repositories/impl/` |
| | Stock Provider (CRUD + 필터 + 유통기한 임박) | `lib/providers/` |
| | Result 패턴 + 에러 타입 | `lib/core/` |
| | Unit Test (CRUD, 필터, 유통기한 로직) | `test/` |
| **Artisan** | FlexColorScheme 테마 (Light/Dark) | `lib/theme/` |
| | go_router 라우팅 설정 | `lib/router/` |
| | 홈 화면 (대시보드) | `lib/views/home/` |
| | 재고 목록 화면 + 필터/정렬 | `lib/views/stock/` |
| | 재고 추가/수정 폼 (form_builder) | `lib/views/stock/` |
| | IngredientCard, ExpiryBadge, CategoryChip 등 위젯 | `lib/widgets/stock/` |
| | 설정 화면 (테마 전환) | `lib/views/settings/` |
| | 온보딩 화면 (3단계) | `lib/views/onboarding/` |
| **Bridge** | Isar DB 초기화 및 마이그레이션 로직 | `lib/services/` |
| **Editor** | — (이 Phase에서 산출물 없음) | — |

### 2.2. 완료 기준

- [ ] 재료 추가/수정/삭제가 정상 동작
- [ ] 카테고리 필터 및 정렬(이름순, 유통기한순) 동작
- [ ] 유통기한 임박(3일) 재고가 홈 대시보드에 표시
- [ ] Light/Dark 테마 전환 동작
- [ ] Isar 영속화 확인 (앱 재시작 후 데이터 유지)
- [ ] 주요 로직 Unit Test 통과
- [ ] `build_runner` 빌드 성공

---

## 3. Phase 1.1 — AI 레시피 추천

> **목표:** 보유 재료를 선택하면 Gemini가 7단계 레시피를 JSON으로 생성.
> **Feature Doc:** `docs/features/ai_recipe.md` (작성 예정)

### 3.1. 에이전트별 산출물

| 에이전트 | 산출물 |
|---------|--------|
| **Architect** | Recipe, RecipeStep, Ingredient, FlavorProfile 등 Freezed 모델 |
| | RecipeRepository 인터페이스 |
| | Recipe Provider (생성, 캐시, 즐겨찾기) |
| **Artisan** | 재료 선택 UI (체크리스트 from 재고) |
| | 레시피 추천 결과 화면 |
| | 레시피 상세 (7단계 조리 가이드 + 타이머) |
| | FlavorRadar 위젯 (맛 프로필 시각화) |
| | RecipeCard, RecipeTypeBadge, CookingStepItem 위젯 |
| | AI 로딩 Lottie + 성공 애니메이션 |
| **Bridge** | GeminiService (API 호출 래퍼) |
| | PromptBuilder (재료 → 구조화 프롬프트) |
| | RecipeGenerationService (프롬프트 → JSON → Recipe) |
| | RecipeRepository 구현체 (Isar 캐시) |

### 3.2. 선행 조건

- Phase 1.0 완료 (StockItem 모델, Isar 인프라)

### 3.3. 완료 기준

- [ ] 재료 선택 → AI 레시피 생성 → 7단계 표시 전체 플로우 동작
- [ ] 캐시 우선순위 (Local → AI) 동작
- [ ] 오프라인 시 캐시된 레시피 표시
- [ ] JSON 파싱 에러 시 재시도 및 사용자 안내

---

## 4. Phase 1.2 — 카메라 OCR 영수증 인식

> **목표:** 영수증을 촬영하면 재료를 자동 인식하여 재고에 추가.
> **Feature Doc:** `docs/features/camera_ocr.md` (작성 예정)

### 4.1. 에이전트별 산출물

| 에이전트 | 산출물 |
|---------|--------|
| **Architect** | OCR 결과 DTO 모델 |
| **Artisan** | 카메라 촬영 화면 + 인식 결과 확인/수정 UI |
| **Bridge** | OcrService (ml_kit 래퍼) + ReceiptParser (텍스트 → 재료) |

### 4.2. 선행 조건

- Phase 1.0 완료

---

## 5. Phase 1.3 — 음성 재료 입력

> **목표:** 음성으로 재료를 말하면 텍스트 변환 후 재고에 추가.
> **Feature Doc:** `docs/features/voice_input.md` (작성 예정)

### 5.1. 에이전트별 산출물

| 에이전트 | 산출물 |
|---------|--------|
| **Architect** | 음성 입력 결과 DTO 모델 |
| **Artisan** | 음성 입력 화면 + 인식 결과 확인/수정 UI |
| **Bridge** | VoiceInputService (speech_to_text) + VoiceParser (텍스트 → 재료) |

### 5.2. 선행 조건

- Phase 1.0 완료

---

## 6. Phase 1.5 — 영상 URL 레시피 추출

> **목표:** YouTube 또는 요리 영상 URL을 입력하면 Gemini가 영상을 분석해 레시피를 자동 추출.

### 6.1. 에이전트별 산출물

| 에이전트 | 산출물 | 파일 |
|---------|--------|------|
| **Architect** | `Recipe.videoUrl` 필드 추가 | `lib/models/recipe.dart` |
| **Artisan** | `_VideoRecipeSection` 위젯 (홈 화면 내 URL 입력 UI) | `lib/views/home/home_screen.dart` |
| | `YoutubePlayerCard` 위젯 (레시피 상세 내 영상 재생) | `lib/widgets/recipe/youtube_player_card.dart` |
| **Bridge** | `GeminiService.generateFromVideoUrl()` (YouTube → fileData, 일반 URL → 텍스트) | `lib/services/gemini_service.dart` |
| | `PromptBuilder.buildVideoRecipePrompt()` | `lib/services/prompt_builder.dart` |
| | `RecipeGenerationService.generateFromVideoUrl()` | `lib/services/recipe_generation_service.dart` |

### 6.2. 동작 방식

- **YouTube URL:** Gemini `fileData` 파라미터로 영상을 직접 분석 (`youtu.be` / `youtube.com` 자동 판별)
- **일반 URL:** 프롬프트 텍스트에 URL을 포함해 컨텍스트로 처리
- 추출 완료 후 `Recipe.videoUrl`에 원본 URL 저장, 레시피 상세에서 플레이어 표시

### 6.3. 완료 기준

- [x] YouTube URL 입력 → Gemini 영상 분석 → 7단계 레시피 추출
- [x] 일반 영상 URL 텍스트 컨텍스트 처리
- [x] 레시피 상세 화면에서 원본 영상 재생 (`YoutubePlayerCard`)
- [x] 홈 화면 `_VideoRecipeSection`에서 URL 입력 진입점 제공

---

## 7. Phase 1.4 — 리워드 시스템

> **목표:** 요리 활동에 보상을 부여하여 지속적 사용 동기 부여.
> **Feature Doc:** `docs/features/reward_system.md`

### 7.1. 에이전트별 산출물

| 에이전트 | 산출물 |
|---------|--------|
| **Architect** | Reward 모델, Achievement 모델, RewardRepository, Reward Provider |
| **Artisan** | 리워드 대시보드, 업적 카드, 축하 애니메이션 |
| **Bridge** | 리워드 로직 트리거 서비스 (Phase 2.0+에서 서버 동기화) |

### 7.2. 선행 조건

- Phase 1.0 + 1.1 완료 (재고 등록·레시피 완료 이벤트 필요)

---

## 8. Phase 2.0 — 백엔드 연동

> **목표:** FastAPI 서버를 구축하여 데이터 동기화 및 서버사이드 AI 처리 기반 마련.

### 8.1. 에이전트별 산출물

| 에이전트 | 산출물 |
|---------|--------|
| **Architect** | Repository 인터페이스에 서버 통신 메서드 추가 |
| **Bridge** | FastAPI 서버 구축 (`backend/`) |
| | PostgreSQL + pgvector DB 스키마 |
| | Docker + docker-compose 환경 |
| | Retrofit 기반 API 클라이언트 (`lib/services/`) |
| | GitHub Actions CI/CD (`infra/`) |

### 8.2. Backend 구조

```
backend/
├── main.py
├── api/routes/
├── core/ (config, security)
├── models/ (SQLAlchemy + Pydantic)
├── services/ (gemini, vector, celery)
├── db/ (session, migrations)
├── Dockerfile
├── docker-compose.yml
└── requirements.txt
```

---

## 9. Phase 2.1 — 레시피 벡터 캐시

> **목표:** pgvector로 재료 조합 유사도를 계산하여 기존 레시피를 재활용.

### 9.1. 에이전트별 산출물

| 에이전트 | 산출물 |
|---------|--------|
| **Bridge** | 벡터 임베딩 생성 서비스, 유사도 검색 API |
| **Architect** | 캐시 우선순위에 서버 캐시 계층 추가 (Local → **Server** → AI) |

---

## 10. Phase 2.6 — Weekly Column 발행

> **목표:** 검수된 요리 지식 칼럼을 앱 내에서 발행·소비.
> **Feature Doc:** `docs/features/weekly_column.md` (작성 예정)

### 10.1. 에이전트별 산출물

| 에이전트 | 산출물 |
|---------|--------|
| **Architect** | Column, ColumnCategory Freezed 모델 + ColumnRepository + Provider |
| **Artisan** | 칼럼 목록/상세 화면, ColumnCard, SourceChip 위젯 |
| **Bridge** | 칼럼 API 클라이언트, 개인화 헤드라인 생성 (Gemini) |
| **Editor** | 시드 칼럼 8편 (`app/assets/columns/columns.json`), 출처 검증 |

### 10.2. Editor 콘텐츠 운영

- **MVP:** 시드 번들 (앱 내장 JSON) → Editor 사전 작성·검수
- **Phase 2.6+:** 서버 발행 (`backend/columns/`) → 정기 칼럼 배포
- **Hybrid Strategy:** 본문은 Editor 작성본만 사용. Gemini는 개인화 헤드라인·요약에만 활용.

---

## 11. Phase 의존성 다이어그램

```
Phase 1.0 (재고)
    │
    ├──→ Phase 1.1 (레시피) ──→ Phase 1.4 (리워드)
    │         │
    │         └──→ Phase 1.5 (영상 URL 레시피)
    │
    ├──→ Phase 1.2 (OCR)
    │
    ├──→ Phase 1.3 (음성)
    │
    └──→ Phase 2.0 (백엔드) ──→ Phase 2.1 (벡터 캐시)
                │
                └──→ Phase 2.6 (칼럼)
```

- Phase 1.0은 모든 후속 Phase의 선행 조건.
- Phase 1.2, 1.3은 1.0만 완료되면 독립 병렬 개발 가능.
- Phase 1.4는 1.1 완료 후 착수 (레시피 완료 이벤트 필요).
- Phase 2.x는 2.0(백엔드) 완료 후 순차 진행.
