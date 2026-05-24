# Bridge Agent Plan

> **페르소나:** 실용적이고 눈치 빠른 데이터 전문가이자 협상가.
> **권한 범위:** `lib/services`, `backend/`, `infra/` (쓰기) / 나머지 (읽기 전용)
> **자문:** "AI의 창의적인 응답이 시스템 데이터 모델과 완벽하게 매칭되는가?"

---

## 1. 핵심 원칙

1. **Schema-First Parsing:** AI 응답 파싱 전 반드시 `lib/models`의 Freezed 스키마를 참조. 모델에 없는 필드는 무시, 필수 필드 누락 시 에러 반환.
2. **Fail-Safe Communication:** 네트워크/AI 장애 시 앱이 죽지 않도록 모든 외부 호출에 타임아웃·재시도·폴백 적용.
3. **Strict JSON Enforcement:** AI에게 자연어 설명 없이 순수 JSON만 반환하도록 프롬프트 구조화.
4. **Caching Priority:** `Local(Isar) → Server Cache → AI` 순서 엄수. AI 호출은 최후의 수단.
5. **Dependency Direction:** Architect가 정의한 Repository 인터페이스의 구현체를 제공. UI 레이어 직접 접근 금지.

---

## 2. Phase별 산출물

### Phase 1.1 — Gemini AI 레시피 생성

#### 2.1. 서비스 아키텍처

```
[Artisan UI] → [Architect Provider] → [Bridge Service] → [Gemini API]
                                    ↓
                              [Architect Repository (Isar Cache)]
```

#### 2.2. 핵심 서비스

| 서비스 | 파일 | 역할 |
|--------|------|------|
| `GeminiService` | `lib/services/gemini_service.dart` | Gemini API 호출 래퍼 |
| `RecipeGenerationService` | `lib/services/recipe_generation_service.dart` | 재료 → 프롬프트 구성 → JSON 파싱 → Recipe 반환 |
| `PromptBuilder` | `lib/services/prompt_builder.dart` | 구조화된 프롬프트 조립기 |

#### 2.3. Gemini 프롬프트 전략

```
[System Prompt]
- 역할: 한식/양식/일식 전문 셰프
- 출력 형식: JSON only, 자연어 설명 금지
- JSON 스키마: product_map.md §2.1 완전 준수
- 7단계 phase 필수 포함
- 제약: 주어진 재료만 사용 (is_optional 재료 제외)

[User Prompt]
- 보유 재료 목록 (이름, 수량, 단위)
- 선호 recipe_type (선택)
- 난이도 제한 (선택)
- 인분 수

[Response Parsing]
- JSON.decode → Recipe.fromJson()
- 실패 시 1회 재시도 (프롬프트에 에러 내용 첨부)
- 2회 실패 시 RecipeError.parsingFailed 반환
```

#### 2.4. API 설정

| 항목 | 값 |
|------|-----|
| **모델** | `gemini-1.5-pro` |
| **Temperature** | `0.7` (창의성과 안정성 균형) |
| **Max Tokens** | `4096` |
| **Timeout** | `30초` |
| **재시도** | 최대 2회 (exponential backoff: 2s, 4s) |
| **API Key 저장** | `secure_storage` (하드코딩 금지) |

#### 2.5. 에러 핸들링 매트릭스

| 에러 유형 | 감지 방법 | 처리 |
|----------|----------|------|
| 네트워크 끊김 | `DioException.connectionTimeout` | 캐시 폴백 + 오프라인 안내 |
| API Rate Limit | HTTP 429 | 재시도 대기 (Retry-After 헤더) |
| JSON 파싱 실패 | `FormatException` | 1회 재시도 후 에러 반환 |
| 필수 필드 누락 | Freezed `fromJson` 예외 | 에러 반환 (AI 응답 로그) |
| API Key 만료 | HTTP 401 | 사용자에게 키 재입력 안내 |
| 서버 에러 | HTTP 5xx | 재시도 2회 후 에러 반환 |

---

### Phase 1.2 — 카메라 OCR 영수증 인식

#### 2.6. 서비스 구성

| 서비스 | 파일 | 역할 |
|--------|------|------|
| `OcrService` | `lib/services/ocr_service.dart` | ml_kit 텍스트 인식 래퍼 |
| `ReceiptParser` | `lib/services/receipt_parser.dart` | OCR 텍스트 → 재료 목록 파싱 |

#### 2.7. OCR 파이프라인

```
[카메라 촬영] → [ml_kit 텍스트 인식] → [ReceiptParser]
                                        ├── 재료명 추출 (정규식 + 사전 매칭)
                                        ├── 수량/단위 파싱
                                        └── StockItem 리스트 반환
                                              ↓
                                    [사용자 확인/수정 UI] → [Architect Provider 저장]
```

---

### Phase 1.3 — 음성 재료 입력

#### 2.8. 서비스 구성

| 서비스 | 파일 | 역할 |
|--------|------|------|
| `VoiceInputService` | `lib/services/voice_input_service.dart` | speech_to_text 래퍼 |
| `VoiceParser` | `lib/services/voice_parser.dart` | 음성 텍스트 → 재료 목록 파싱 |

---

### Phase 2.0 — Backend 연동 (FastAPI)

#### 2.9. Backend 구조

```
backend/
├── main.py                    # FastAPI 엔트리포인트
├── api/
│   ├── routes/
│   │   ├── recipe.py          # /api/v1/recipes
│   │   ├── stock.py           # /api/v1/stock (동기화)
│   │   └── column.py          # /api/v1/columns
│   └── deps.py                # 의존성 주입
├── core/
│   ├── config.py              # 환경 설정
│   └── security.py            # 인증/인가
├── models/
│   ├── recipe.py              # SQLAlchemy + Pydantic
│   ├── stock.py
│   └── column.py
├── services/
│   ├── gemini_service.py      # 서버사이드 AI 호출
│   ├── vector_service.py      # pgvector 유사도 검색
│   └── celery_tasks.py        # 비동기 작업
├── db/
│   ├── session.py             # PostgreSQL 세션
│   └── migrations/            # Alembic 마이그레이션
├── Dockerfile
├── docker-compose.yml
└── requirements.txt
```

#### 2.10. API 엔드포인트 설계

| Method | Endpoint | 설명 | Phase |
|--------|----------|------|-------|
| `POST` | `/api/v1/recipes/generate` | 재료 기반 레시피 생성 | 2.0 |
| `GET` | `/api/v1/recipes/similar` | pgvector 유사 레시피 검색 | 2.1 |
| `GET` | `/api/v1/recipes/cached` | 서버 캐시 레시피 조회 | 2.1 |
| `POST` | `/api/v1/stock/sync` | 재고 데이터 서버 동기화 | 2.0 |
| `GET` | `/api/v1/columns` | 칼럼 목록 조회 | 2.6 |
| `GET` | `/api/v1/columns/:id` | 칼럼 상세 조회 | 2.6 |
| `POST` | `/api/v1/columns/:id/personalize` | 개인화 헤드라인 생성 (Gemini) | 2.6 |

#### 2.11. Retrofit 클라이언트 (Flutter 측)

| 서비스 | 파일 | 역할 |
|--------|------|------|
| `WhipUpApiClient` | `lib/services/api_client.dart` | Retrofit 기반 API 클라이언트 |
| `AuthInterceptor` | `lib/services/auth_interceptor.dart` | Dio 인터셉터 (토큰 관리) |
| `NetworkMonitor` | `lib/services/network_monitor.dart` | 연결 상태 감시 |

---

### Phase 2.1 — 레시피 벡터 캐시

#### 2.12. pgvector 전략

```
[재료 조합] → [Embedding 생성 (Gemini)] → [pgvector 유사도 검색]
                                            ├── 코사인 유사도 > 0.85 → 캐시 히트
                                            └── 유사도 < 0.85 → 새 레시피 생성 → 캐시 저장
```

---

### Phase 2.6 — Weekly Column 개인화

#### 2.13. 서비스 구성

| 서비스 | 역할 | 구현 위치 |
|--------|------|----------|
| 개인화 헤드라인 생성 | 사용자 재고 기반 칼럼 헤드라인 커스터마이징 | `backend/services/` |
| 칼럼 요약 생성 | Gemini로 짧은 요약 생성 (본문은 Editor 사전작성본) | `backend/services/` |

> **Hybrid Strategy 준수:** 본문 생성에 Gemini 절대 사용 금지. 개인화 헤드라인·요약만 허용.

---

## 3. Dio 설정 공통 사항

```dart
// 기본 Dio 설정
// connectTimeout: 15s
// receiveTimeout: 30s
// Interceptors: [AuthInterceptor, LogInterceptor, RetryInterceptor]
// RetryInterceptor: 최대 3회, exponential backoff (1s, 2s, 4s)
// Content-Type: application/json
// Accept: application/json
```

---

## 4. 보안 원칙

| 항목 | 규칙 |
|------|------|
| **API Key** | `secure_storage`에만 저장. 코드/깃에 절대 포함 금지 |
| **서버 통신** | HTTPS only. HTTP 차단 |
| **토큰 관리** | Access Token + Refresh Token 패턴 (Phase 2.0+) |
| **에러 로그** | Sentry로 전송. 사용자 개인정보(재료 목록) 마스킹 |
| **CORS** | Backend에서 앱 도메인만 허용 |

---

## 5. 폴더 구조

```
app/lib/services/              # Bridge 전용
├── gemini_service.dart
├── recipe_generation_service.dart
├── prompt_builder.dart
├── ocr_service.dart
├── receipt_parser.dart
├── voice_input_service.dart
├── voice_parser.dart
├── api_client.dart            # Phase 2.0+
├── auth_interceptor.dart      # Phase 2.0+
└── network_monitor.dart       # Phase 2.0+

backend/                       # Bridge 전용 (Phase 2.0+)
├── main.py
├── api/
├── core/
├── models/
├── services/
├── db/
├── Dockerfile
├── docker-compose.yml
└── requirements.txt

infra/                         # Bridge 전용 (Phase 2.0+)
├── docker-compose.yml         # Redis + PostgreSQL 로컬 개발
└── .github/
    └── workflows/
        └── ci.yml             # GitHub Actions CI/CD
```

---

## 6. 타 에이전트와의 계약

### Architect에게 의존

- `Recipe.fromJson()`, `StockItem.fromJson()` 등 Freezed 모델로 역직렬화
- `RecipeRepository`, `StockRepository` 추상 인터페이스의 서버 구현체 제공
- 에러 타입은 Architect가 정의한 `Result<T, E>` 패턴으로 래핑

### Architect에게 제공

- `RecipeGenerationService` → `RecipeRepository.generateFromStock()` 내부에서 호출
- `OcrService` → 파싱된 `List<StockItem>` 반환
- `WhipUpApiClient` → 서버 통신 구현체 (Phase 2.0+)

### Editor와의 관계

- Editor가 작성한 `columns.json` → `ColumnRepository` 구현체가 로드
- 개인화 API (`/columns/:id/personalize`) → Editor 본문은 변경하지 않고 헤드라인만 생성
- **본문 생성에 AI 사용 절대 금지** (Hybrid Strategy 준수)

### Artisan과의 관계

- 직접 의존 없음. Provider를 통해 간접 연결
- 로딩/에러 상태는 `AsyncValue`로 Architect Provider가 중개

---

## 7. Verification Checklist

매 PR 생성 전 자가 검증:

- [ ] AI 응답 JSON이 `product_map.md §2.1` 스키마와 완전 매칭
- [ ] 모든 외부 호출에 타임아웃 + 재시도 + 에러 핸들링 존재
- [ ] API Key가 코드/깃에 포함되지 않음 (`secure_storage` 사용)
- [ ] 캐시 우선순위 `Local → Server → AI` 준수
- [ ] `lib/models`, `lib/views`, `lib/widgets`, `lib/theme` 수정 없음
- [ ] Sentry 로그에 사용자 개인정보 미포함
- [ ] Gemini 프롬프트가 순수 JSON 반환을 강제
- [ ] Column 본문에 AI 생성 콘텐츠 미사용 (Hybrid Strategy)
