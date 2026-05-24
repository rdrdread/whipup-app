# 카메라 OCR 영수증 인식 (Phase 1.2)

> **Phase:** 1.2
> **선행 조건:** Phase 1.0 완료 (StockItem 모델, Isar 인프라, SubCategoryService)
> **참조 에이전트:** Architect (DTO/Provider), Artisan (카메라 UI/인식 결과 UX), Bridge (ml_kit/파싱 파이프라인)
> **상위 문서:** `roadmap.md §4`, `product_map.md §6.2`, `screen_layout.md §2.1 (/camera)`

---

## 1. Feature Summary

마트 영수증을 촬영하면 `google_mlkit_text_recognition`이 텍스트를 추출하고,
`ReceiptParser`가 식재료 항목을 파싱하여 재고 등록 화면으로 연결하는 **터치 한 번짜리 재고 일괄 등록** 기능.

> **Design Creed 연결:** *"가벼운 인터랙션을 지향"* — 영수증 하나로 20가지 재료를 한번에 등록.
> 복잡한 OCR 파이프라인은 스캔 애니메이션 뒤로 숨기고, 사용자 눈에는 깔끔한 인식 결과 리스트만 보인다.
> *"주방의 동선을 닮도록"* — 장보기(영수증) → 확인(편집) → 저장의 3단계가 실제 재료 정리 동선과 일치한다.

**OCR 파이프라인 요약:**

```
카메라 촬영
    │
    ▼
ml_kit TextRecognition (디바이스 내 처리, 네트워크 불필요)
    │
    ▼
ReceiptParser: 텍스트 블록 → OcrItem 목록 (식재료 필터링)
    │
    ├── 명확한 항목 → OcrItem (바로 확인 화면 진입)
    └── 모호한 항목 → Gemini 보조 파싱 (선택적, Phase 1.2+)
           │
           ▼
인식 결과 확인/편집 화면 → 사용자 승인
    │
    ▼
StockRepository.add() 일괄 저장
```

---

## 2. User Stories

### US-1: 영수증 촬영으로 재고 일괄 등록
> "마트 다녀오면 영수증이 있는데, 일일이 입력하기 귀찮다."

- **Given:** 재고 목록 화면에서 FAB 장기 탭 또는 AppBar 카메라 아이콘 탭
- **When:** 카메라 화면에서 영수증을 가이드라인 안에 맞추고 셔터를 탭
- **Then:** 스캔 애니메이션이 재생되며 OCR 처리
- **And:** 인식된 식재료 항목 목록이 결과 확인 화면에 슬라이드업으로 등장
- **And:** `HapticFeedback.mediumImpact()` 재생

### US-2: 인식 결과 검토 및 편집
> "인식이 잘못된 항목을 수정하거나 필요 없는 건 빼고 싶다."

- **Given:** 인식 결과 확인 화면
- **When:** 특정 OcrItem의 재료명/수량/카테고리를 인라인 편집
- **Then:** 즉시 반영되어 확인 목록 업데이트
- **And:** 불필요한 항목(예: 비닐봉지, 포인트 적립)은 스와이프로 제거

### US-3: 비식품 항목 자동 필터링
> "영수증에 칫솔, 세제도 있는데 재료만 나왔으면 좋겠다."

- **Given:** OCR 결과에 식품 + 비식품 항목이 혼재
- **When:** ReceiptParser가 카테고리 추론
- **Then:** 비식품 항목(생활용품, 위생용품 등)은 기본적으로 미선택 상태로 표시
- **And:** 사용자가 원하면 체크하여 포함 가능

### US-4: 카테고리 자동 매핑
> "삼겹살이면 알아서 육류로 분류해 주면 좋겠다."

- **Given:** 인식된 재료명 (예: "국내산 삼겹살 500g")
- **When:** ReceiptParser가 키워드 매핑 테이블로 StockCategory 추론
- **Then:** 재료명, 수량, 단위, 카테고리가 자동 설정된 OcrItem 생성
- **And:** 확신도가 낮은 항목은 "확인 필요" 뱃지 표시

### US-5: 일괄 저장
> "확인 다 했으면 한 번에 냉장고에 넣고 싶다."

- **Given:** 결과 확인 화면에서 체크된 항목 1개 이상
- **When:** [N개 재고에 추가하기] CTA 탭
- **Then:** 선택된 모든 OcrItem이 StockItem으로 변환되어 Isar에 일괄 저장
- **And:** 성공 Lottie 1회 재생 + `HapticFeedback.mediumImpact()`
- **And:** 재고 목록 화면으로 이동, 방금 추가된 항목 상단 하이라이트

### US-6: 카메라 권한 요청
> "앱이 카메라를 왜 쓰는지 알고 싶다."

- **Given:** 최초 카메라 기능 진입
- **When:** 카메라 권한 미허용 상태
- **Then:** 권한 목적 설명 다이얼로그 표시 후 시스템 권한 요청
- **And:** 거부 시 "설정에서 카메라 권한을 허용해 주세요" 안내 + 설정 앱 이동 버튼

### US-7: 이미지 품질 불량 재촬영
> "사진이 흔들렸는지 인식이 너무 안 된다."

- **Given:** 촬영 후 인식된 항목이 0개이거나 신뢰도가 매우 낮음
- **When:** OCR 처리 완료
- **Then:** "영수증을 읽지 못했어요" 안내 + [다시 찍기] 버튼
- **And:** 촬영 팁(밝은 곳, 평평하게, 가이드라인 맞추기) 표시

---

## 3. Acceptance Criteria

| # | 기준 | 검증 방법 | 에이전트 |
|---|------|----------|---------|
| AC-1 | 카메라 권한 없을 때 목적 설명 후 요청 | 수동 테스트 | Artisan |
| AC-2 | 셔터 탭 → OCR 처리 → 결과 화면 진입까지 3초 이내 (일반 조명) | 수동 측정 | Bridge |
| AC-3 | 국문 영수증 식재료 항목 인식률 80% 이상 (표준 마트 영수증 기준) | 수동 테스트 10건 | Bridge |
| AC-4 | 비식품 항목(생활용품·포인트·봉투)은 기본 미선택 | Unit Test | Bridge |
| AC-5 | 인식된 항목의 재료명·수량·단위 인라인 편집 가능 | UI 확인 | Artisan |
| AC-6 | 스와이프로 항목 제거 가능, 제거된 항목 "되돌리기" 지원 | UI 확인 | Artisan |
| AC-7 | [N개 추가하기] 탭 → 선택 항목 전부 Isar에 일괄 저장 | Unit Test | Bridge |
| AC-8 | 저장 완료 후 재고 목록 화면으로 이동 | UI 확인 | Artisan |
| AC-9 | 인식 항목 0개 또는 신뢰도 < 임계값 → 재촬영 안내 | Unit Test | Bridge |
| AC-10 | 카테고리 자동 매핑: 육류/채소/해산물 등 주요 카테고리 정확도 90% | Unit Test | Bridge |
| AC-11 | 확신도 낮은 항목에 "확인 필요" 뱃지 표시 | UI 확인 | Artisan |
| AC-12 | OCR은 디바이스 내 처리 (ml_kit), 네트워크 불필요 | 오프라인 테스트 | Bridge |
| AC-13 | 촬영 가이드라인 오버레이 및 실시간 엣지 감지 피드백 | UI 확인 | Artisan |
| AC-14 | 저장 성공 시 성공 Lottie + `mediumImpact()` | UI 확인 | Artisan |

---

## 4. Data Requirements (Architect)

> 모든 DTO는 Freezed + `fromJson`/`toJson` 포함. OCR 결과는 `StockItem`으로 변환되며 `lib/models/`에 위치한다.

### 4.1. OcrItem — OCR 인식 단일 항목 DTO

```dart
/// OCR로 인식된 영수증 한 줄 항목.
/// ReceiptParser가 생성하고, 사용자 확인 후 [StockItem]으로 변환된다.
@freezed
class OcrItem with _$OcrItem {
  const OcrItem._();

  const factory OcrItem({
    /// 파서가 추출한 재료명 (정규화 전 원문)
    required String rawName,
    /// 정규화된 재료명 (편집 가능)
    required String name,
    /// 수량 (편집 가능)
    @Default(1.0) double quantity,
    /// 단위 (편집 가능, 카테고리 기반 자동 추천)
    @Default('개') String unit,
    /// 자동 추론된 카테고리
    StockCategory? category,
    /// 자동 추론된 서브 카테고리
    String? subCategory,
    /// 파서 확신도 0.0~1.0
    @Default(0.0) double confidence,
    /// 식품 여부 (false = 비식품, 기본 미선택)
    @Default(true) bool isFood,
    /// 사용자 선택 여부 (저장 대상 포함 여부)
    @Default(true) bool isSelected,
  }) = _OcrItem;

  factory OcrItem.fromJson(Map<String, dynamic> json) =>
      _$OcrItemFromJson(json);

  /// OcrItem → StockItem 변환.
  /// [location]은 사용자가 저장 시 선택한 보관 위치.
  StockItem toStockItem({required StorageLocation location}) => StockItem(
        id: 0,
        name: name,
        category: category ?? StockCategory.other,
        subCategory: subCategory,
        storageLocation: location,
        quantity: quantity,
        unit: unit,
        addedAt: DateTime.now(),
      );
}
```

### 4.2. OcrResult — 영수증 1장 파싱 결과

```dart
/// 영수증 한 장의 OCR 처리 전체 결과.
@freezed
class OcrResult with _$OcrResult {
  const factory OcrResult({
    /// 파싱된 항목 전체 (식품 + 비식품 포함)
    required List<OcrItem> items,
    /// 원본 ml_kit 추출 텍스트 (디버그·재파싱용)
    required String rawText,
    /// 전체 처리 신뢰도 점수 (평균 confidence)
    required double overallConfidence,
    /// OCR 처리 시각
    required DateTime processedAt,
    /// 재촬영 권장 여부 (overallConfidence < 0.4)
    @Default(false) bool needsRetake,
  }) = _OcrResult;

  factory OcrResult.fromJson(Map<String, dynamic> json) =>
      _$OcrResultFromJson(json);
}
```

### 4.3. CameraPermissionStatus Enum

```dart
enum CameraPermissionStatus {
  granted,     // 허용됨
  denied,      // 거부됨
  permanentlyDenied, // 영구 거부 (설정에서만 변경 가능)
  undetermined,      // 아직 요청 전
}
```

### 4.4. OcrRepository 인터페이스 (`lib/repositories/ocr_repository.dart`)

```dart
/// OCR 처리 및 결과 저장 추상 인터페이스.
/// Bridge가 구현체를 제공한다.
abstract class OcrRepository {
  /// 이미지 경로를 받아 OCR 처리 후 결과 반환.
  Future<Result<OcrResult, AppError>> processImage(String imagePath);

  /// 선택된 OcrItem 목록을 StockItem으로 일괄 저장.
  Future<Result<int, AppError>> saveItems({
    required List<OcrItem> items,
    required StorageLocation location,
  });
}
```

### 4.5. Provider 구조 (`lib/providers/ocr_providers.dart`)

| Provider | 타입 | 역할 |
|----------|------|------|
| `cameraPermissionProvider` | `AsyncNotifier<CameraPermissionStatus>` | 권한 상태 감시 및 요청 |
| `ocrResultProvider` | `AsyncNotifier<OcrResult?>` | OCR 처리 요청·결과 관리 |
| `ocrItemsNotifierProvider` | `Notifier<List<OcrItem>>` | 인식 결과 편집 상태 (선택/해제/수정) |
| `selectedOcrItemsProvider` | `Provider<List<OcrItem>>` | 저장 대상 필터링 (isSelected == true) |
| `ocrSaveProvider` | `AsyncNotifier<int>` | 일괄 저장 실행 및 결과 |

**`ocrResultProvider` 상태 흐름:**

```
[idle]
  │ processImage(path) 호출
  ▼
[loading] ← 스캔 Lottie 표시
  │ 성공 (overallConfidence >= 0.4)
  ▼
[data: OcrResult] ← 결과 확인 화면으로 자동 전환
  │ 실패 또는 confidence < 0.4
  ▼
[data: OcrResult(needsRetake: true)] ← 재촬영 안내 화면
  │ 에러 (권한 거부, 처리 실패)
  ▼
[error: AppError] ← 에러 UI 표시
```

---

## 5. Bridge 설계 (OCR 파이프라인)

### 5.1. OcrService (`lib/services/ocr_service.dart`)

```dart
/// google_mlkit_text_recognition 래퍼.
/// 디바이스 내 처리 — 네트워크 불필요.
abstract class OcrService {
  /// 이미지 파일 경로를 받아 추출된 텍스트 블록 목록을 반환.
  Future<Result<List<TextBlock>, AppError>> extractText(String imagePath);
}
```

- **패키지:** `google_mlkit_text_recognition: ^0.13.1`
- **스크립트 언어:** `TextRecognitionScript.korean` + `TextRecognitionScript.latin` 병렬 처리
- **처리 위치:** 디바이스 온디바이스 (AC-12)
- **입력 이미지:** JPEG, 해상도 최대 2048×2048으로 다운샘플링 (처리 속도 최적화)

### 5.2. ReceiptParser (`lib/services/receipt_parser.dart`)

영수증 텍스트 블록을 `OcrItem` 목록으로 변환하는 핵심 파싱 엔진.

**파싱 단계:**

```
Step 1: 텍스트 정규화
  - 영수증 헤더(상호명, 날짜, 전화번호) 제거
  - 가격·합계 라인 제거 (숫자만 있는 줄, ₩ 포함 줄)
  - 특수문자 정리, 전각 → 반각 변환

Step 2: 항목 라인 파싱
  - 패턴: [재료명] [수량] [단위] (예: "국내산 삼겹살 500 g")
  - 수량·단위 정규식: r'(\d+(?:\.\d+)?)\s*(g|kg|ml|l|개|묶음|팩|봉|캔|병)'
  - 수량·단위 미표기 시: quantity=1, unit='개' 기본값

Step 3: 재료명 정규화
  - "국내산", "특품", "1등급" 등 품질 수식어 제거
  - "냉장", "냉동", "신선" 등 보관 수식어 → StorageLocation 힌트로 추출
  - 브랜드명 분리 (예: "[CJ] 비비고 왕교자" → "왕교자")

Step 4: 카테고리 추론 (KeywordMap)
  - 키워드 → StockCategory 매핑 테이블 조회 (오프라인, 500+ 키워드)
  - 매핑 성공 → confidence 0.9 / 부분 매핑 → 0.6 / 미매핑 → 0.3

Step 5: 식품/비식품 분류
  - 비식품 키워드셋: ['봉투', '비닐', '포인트', '적립', '할인', '쿠폰',
                     '치약', '칫솔', '세제', '샴푸', '휴지', ...]
  - isFood = false → isSelected = false (기본 미선택)
```

**카테고리 키워드 매핑 테이블 예시:**

| 키워드 | StockCategory | 서브 카테고리 | 기본 단위 |
|--------|--------------|-------------|----------|
| 삼겹살, 목살, 갈비, 등심 | `meat` | 돼지고기 / 소고기 | g |
| 닭가슴살, 닭다리, 통닭 | `meat` | 닭고기 | g |
| 연어, 고등어, 광어, 참치 | `seafood` | 생선 | g |
| 바지락, 홍합, 새우, 오징어 | `seafood` | 해산물 | g |
| 배추, 시금치, 상추, 깻잎 | `vegetable` | 잎채소 | g |
| 당근, 감자, 양파, 무 | `vegetable` | 뿌리채소 | 개 |
| 사과, 배, 딸기, 바나나 | `fruit` | 과일 | 개 |
| 우유, 치즈, 버터, 요거트 | `dairy` | 유제품 | g / ml |
| 쌀, 밀가루, 국수, 라면 | `grain` | 곡물 | g |
| 간장, 고추장, 된장, 소금 | `seasoning` | 양념 | g / ml |
| 주스, 탄산수, 이온음료 | `beverage` | 음료 | ml |
| 냉동만두, 냉동피자, 아이스크림 | `frozen` | 냉동식품 | 개 / g |

### 5.3. Gemini 보조 파싱 (모호 항목 처리)

ReceiptParser가 confidence < 0.5로 분류한 항목에 한해 선택적으로 Gemini 호출.

```dart
/// Gemini에 단일 항목 분류 요청.
/// 네트워크 필요. 오프라인 시 confidence 0.3으로 OcrItem 그대로 반환.
Future<Result<OcrItem, AppError>> classifyWithGemini(String rawText);
```

**프롬프트 템플릿:**
```
다음 영수증 텍스트가 식재료인지 분류하고, 식재료라면 카테고리와 수량·단위를 JSON으로만 응답하세요.
텍스트: "{rawText}"
응답 형식: {"is_food": bool, "name": str, "category": str, "quantity": float, "unit": str}
```

- 호출 조건: confidence < 0.5 항목, 오프라인 시 스킵
- 최대 호출: 영수증당 5건 제한 (비용 통제)
- Timeout: 5초 (초과 시 ml_kit 결과 그대로 사용)

### 5.4. 에러 핸들링

| 상황 | 처리 |
|------|------|
| 카메라 권한 거부 | 목적 설명 다이얼로그 → 시스템 권한 요청 → 거부 시 설정 안내 |
| 이미지 처리 실패 | `AppError.ocr('인식 실패')` + 재촬영 안내 |
| 인식 항목 0개 | `OcrResult(needsRetake: true)` 반환 |
| overallConfidence < 0.4 | 재촬영 권장 (사용자가 그냥 진행할 수도 있음) |
| Gemini 오프라인 | ml_kit 결과만으로 진행 (Gemini 생략) |
| 일괄 저장 중 일부 실패 | 성공 건수 반환 + 실패 항목 수 Snackbar 안내 |

### 5.5. 이미지 처리 (`lib/services/image_processing_service.dart`)

```dart
/// 촬영 이미지 전처리 서비스.
abstract class ImageProcessingService {
  /// 원본 이미지를 OCR 최적화 형태로 전처리.
  ///  - 해상도 다운샘플링 (max 2048×2048)
  ///  - 자동 회전 보정 (EXIF 기반)
  ///  - 명도/대비 자동 보정 (어두운 영수증 보완)
  Future<String> preprocess(String rawImagePath);
}
```

---

## 6. UI Requirements (Artisan)

> 타이포그래피 상세: `design_system.md §1.2.4` 참조.
> 레이아웃 원칙: `screen_layout.md §2.1 (/camera)` 참조.
> 컬러 토큰: 하드코딩 금지, `Theme.of(context)` 및 FlexColorScheme 시멘틱 컬러 사용.

### 6.1. 화면 구성

#### 6.1.1. 카메라 촬영 화면 (`/camera`)

```
┌──────────────────────────────┐
│ StatusBar (투명, 아이콘 흰색)   │
├──────────────────────────────┤
│                              │
│   ← 닫기           💡 팁     │  ← IconButton 48dp, 흰색
│                              │
│  ┌────────────────────────┐  │
│  │                        │  │
│  │   카메라 라이브 프리뷰    │  │  ← CameraPreview 전체 화면
│  │                        │  │
│  │  ┌──────────────────┐  │  │
│  │  │                  │  │  │  ← 영수증 가이드라인 (둥근 모서리 사각형)
│  │  │  여기에 영수증을   │  │  │     Flame Orange stroke 2dp
│  │  │  맞춰 주세요 📄  │  │  │
│  │  │                  │  │  │
│  │  └──────────────────┘  │  │
│  │                        │  │
│  │  ───── 스캔 라인 ─────   │  │  ← 촬영 전: 위아래 반복 이동 애니메이션
│  │                        │  │
│  └────────────────────────┘  │
│                              │
│         [📷 셔터]              │  ← 68dp 원형 버튼, Primary
│                              │
│   갤러리에서 선택               │  ← TextButton, 보조 진입점
│                              │
└──────────────────────────────┘
```

**엣지 감지 피드백:**
- 영수증이 가이드라인 내에 감지되면 → 가이드라인 스트로크가 `freshGreen`으로 변경 (300ms)
- 감지되지 않으면 → `warningAmber` 색상 유지

#### 6.1.2. OCR 처리 중 오버레이

```
┌──────────────────────────────┐
│                              │
│   [캡처된 이미지 섬네일]         │  ← 블러 처리된 배경
│                              │
│   ┌──────────────────────┐   │
│   │  [스캔 Lottie 128dp]  │   │  ← 스캔 바 이동 애니메이션
│   │                      │   │
│   │  영수증을 읽고 있어요  │   │  ← bodyLarge
│   │  잠깐만 기다려 주세요  │   │
│   └──────────────────────┘   │
│                              │
└──────────────────────────────┘
```

#### 6.1.3. 인식 결과 확인 화면 (`/camera/review`)

```
┌──────────────────────────────┐
│ AppBar: "인식 결과"  [다시찍기]  │
├──────────────────────────────┤
│ 저장할 재고함                  │
│ [🧊냉장고✓] [❄️냉동고] [📦팬트리]│  ← 보관 위치 선택 칩 (공통 일괄 적용)
├──────────────────────────────┤
│ 🥩 식재료 12개 인식됨           │  ← titleMedium
│ (체크 해제하면 저장 제외됩니다)   │  ← bodySmall
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ ✅ 🥩 삼겹살     500g [편집]│ │  ← OcrItemCard (선택됨)
│ ├──────────────────────────┤ │
│ │ ✅ 🥬 배추      1개   [편집]│ │
│ ├──────────────────────────┤ │
│ │ ✅ 🐟 연어      200g [편집]│ │
│ ├──────────────────────────┤ │
│ │ ⚠ ☑ 가공식품류  1개  [편집]│ │  ← "확인 필요" 뱃지 (warningAmber)
│ ├──────────────────────────┤ │
│ │ ─ ☐ 비닐봉투    1개       │ │  ← 비식품 (기본 미선택, 회색)
│ └──────────────────────────┘ │
│                              │
│ ┌──────────────────────────┐ │
│ │ [12개 재고에 추가하기]  CTA│ │  ← Filled Button, Primary
│ └──────────────────────────┘ │
├──────────────────────────────┤
│ [홈] [재고] [레시피] [마이]    │
└──────────────────────────────┘
```

#### 6.1.4. 재촬영 안내 화면

```
┌──────────────────────────────┐
│ AppBar: "인식 결과"             │
├──────────────────────────────┤
│                              │
│      📄❓                     │  ← 이모지 64dp
│                              │
│  영수증을 읽지 못했어요         │  ← headlineSmall
│                              │
│  촬영 팁                      │  ← titleSmall
│  • 밝은 곳에서 촬영하세요       │
│  • 영수증을 평평하게 펴 주세요  │  ← bodyMedium
│  • 가이드라인 안에 맞춰 주세요  │
│  • 글자가 잘 보이는지 확인하세요 │
│                              │
│ ┌──────────────────────────┐ │
│ │     [다시 찍기]   CTA     │ │
│ └──────────────────────────┘ │
│                              │
│      수동으로 입력하기          │  ← TextButton → /stock/add
│                              │
└──────────────────────────────┘
```

### 6.2. 위젯 목록

| 위젯 | 위치 | 역할 |
|------|------|------|
| `ReceiptGuideOverlay` | `/camera` | 가이드라인 사각형 + 엣지 감지 색상 피드백 |
| `ScanLineAnimation` | `/camera` | 스캔 중 위아래 이동하는 라인 (CustomPainter) |
| `ShutterButton` | `/camera` | 68dp 원형 촬영 버튼 + 탭 피드백 |
| `OcrProcessingOverlay` | 촬영 후 | 스캔 Lottie + 로딩 텍스트 |
| `OcrItemCard` | `/camera/review` | 인식 항목 1건: 체크박스+이모지+이름+수량+편집 |
| `OcrItemEditSheet` | OcrItemCard 탭 | 바텀시트 인라인 편집 (이름/수량/단위/카테고리) |
| `ConfidenceBadge` | OcrItemCard 내부 | "확인 필요 ⚠" 뱃지 (confidence < 0.6) |
| `StorageLocationChips` | `/camera/review` 상단 | 일괄 보관 위치 선택 칩 그룹 |
| `OcrSuccessOverlay` | 저장 완료 | 성공 Lottie 전체화면 (1.5초 후 재고 화면으로) |
| `RetakeGuideView` | 인식 실패 | 재촬영 안내 + 팁 목록 |

### 6.3. 상호작용 및 애니메이션

| 이벤트 | 효과 | 타이밍 |
|--------|------|--------|
| 셔터 버튼 탭 | 셔터 스케일 0.9→1.0 (100ms) + `mediumImpact()` | 탭 즉시 |
| 영수증 감지 (가이드라인 안) | 가이드라인 색상 Amber→Green (300ms) | 실시간 |
| OCR 결과 등장 | OcrItemCard 슬라이드업 stagger (80ms 간격) | 화면 전환 후 |
| OcrItemCard 체크 토글 | `selectionClick()` + 체크 스케일 팝 | 즉시 |
| 항목 스와이프 삭제 | `heavyImpact()` + 슬라이드아웃 (200ms) | 스와이프 완료 |
| 저장 완료 | `mediumImpact()` + 성공 Lottie (1.5초) | 저장 완료 즉시 |
| 가이드라인 내 스캔 라인 | 위→아래 1.5초 루프 (EaseInOut) | 카메라 진입 후 |

### 6.4. 타이포그래피 매핑

| 요소 | 스타일 | 예시 |
|------|--------|------|
| AppBar 제목 | `titleLarge` (20sp SemiBold) | "인식 결과" |
| 인식 항목 수 헤더 | `titleMedium` | "🥩 식재료 12개 인식됨" |
| OcrItemCard 재료명 | `titleSmall` | "삼겹살" |
| OcrItemCard 수량·단위 | `bodyMedium` | "500g" |
| 확인 필요 뱃지 | `labelSmall` + warningAmber | "확인 필요 ⚠" |
| 비식품 항목 | `bodyMedium` + onSurfaceVariant | "비닐봉투 (1개)" |
| 저장 CTA | `labelLarge` | "12개 재고에 추가하기" |
| 재촬영 안내 제목 | `headlineSmall` | "영수증을 읽지 못했어요" |
| 촬영 팁 항목 | `bodyMedium` | "밝은 곳에서 촬영하세요" |
| 보조 액션 | `labelLarge` + TextButton | "다시 찍기", "수동으로 입력하기" |

### 6.5. 진입점

| 진입 경로 | 트리거 |
|----------|--------|
| 재고 목록 AppBar의 카메라 아이콘 | 아이콘 탭 |
| 재고 추가 화면의 [영수증 촬영] 버튼 | 버튼 탭 |
| 홈 대시보드의 "영수증 찍기" 퀵 액션 (Phase 1.2+) | 카드 탭 |

---

## 7. Edge Cases

| 상황 | 처리 |
|------|------|
| 카메라 권한 영구 거부 | "설정에서 권한을 허용해 주세요" + 설정 앱 이동 버튼 |
| 갤러리 이미지 선택 (영수증 아닌 경우) | 재촬영 안내 화면 (confidence < 0.4) |
| 영어 영수증 (해외 마트) | `latin` 스크립트로 파싱 시도. 인식률 낮아도 원문 표시 후 수동 편집 유도 |
| 손으로 쓴 메모 (장보기 목록) | OCR 인식률 낮음. 재촬영 또는 수동 입력 안내 |
| 영수증이 여러 장 (대량 구매) | 1회 촬영 = 1장 처리. "다시 찍기"로 추가 영수증 스캔 후 누적 저장 |
| 이미 등록된 재료와 중복 | 허용 (수량이 다를 수 있음). 중복 알림 없음 (수동 재고 규칙 동일) |
| 항목명이 너무 길어 UI 넘침 | OcrItemCard: 1줄 ellipsis. 편집 시트에서 전체 표시 |
| 수량·단위 파싱 불가 (예: "한봉지") | quantity=1, unit='봉' 기본값. "확인 필요" 뱃지 |
| 저장 중 앱 백그라운드 전환 | Isolate 내 저장 계속. 복귀 시 결과 Snackbar 표시 |
| 냉장/냉동 표기 재료 | StorageLocation 힌트로 추출 → 보관 위치 칩 자동 선택 (사용자 변경 가능) |

---

## 8. 선행 조건 및 의존성

```
Phase 1.0 (재고 관리)
└── StockItem 모델, StockCategory enum, StorageLocation enum
    SubCategoryService (키워드 → 카테고리 매핑 재사용)
    StockRepository.add() (일괄 저장에 사용)
    Isar 인프라

Phase 1.2 (본 문서)
├── Architect: OcrItem, OcrResult DTO, OcrRepository 인터페이스
│             cameraPermissionProvider, ocrResultProvider,
│             ocrItemsNotifierProvider, selectedOcrItemsProvider
├── Bridge:   OcrService (ml_kit 래퍼), ReceiptParser (키워드 파싱)
│             ImageProcessingService (전처리)
│             GeminiService 재사용 (모호 항목 보조 파싱)
└── Artisan:  /camera + /camera/review 화면
              ReceiptGuideOverlay, ScanLineAnimation, OcrItemCard 등 위젯

Phase 1.3 (음성 입력) — 병렬 개발 가능 (1.0 완료면 독립)
Phase 2.0+ — OcrResult를 서버에 로깅하여 파싱 모델 개선 가능
```

---

## 9. 파일 구조

```
app/lib/
├── models/
│   ├── ocr_item.dart                  # Architect — OcrItem Freezed DTO
│   ├── ocr_result.dart                # Architect — OcrResult Freezed DTO
│   └── camera_permission_status.dart  # Architect — enum
│
├── repositories/
│   ├── ocr_repository.dart                    # Architect — interface
│   └── impl/
│       └── ml_kit_ocr_repository.dart         # Bridge — implementation
│
├── providers/
│   └── ocr_providers.dart             # Architect — 5 providers
│
├── services/
│   ├── ocr_service.dart               # Bridge — ml_kit 래퍼
│   ├── receipt_parser.dart            # Bridge — 텍스트 → OcrItem 파싱
│   └── image_processing_service.dart  # Bridge — 이미지 전처리
│
├── views/
│   └── camera/
│       ├── camera_screen.dart         # Artisan — 카메라 촬영
│       └── ocr_review_screen.dart     # Artisan — 인식 결과 확인
│
└── widgets/
    └── camera/
        ├── receipt_guide_overlay.dart  # Artisan — 가이드라인 + 엣지 감지
        ├── scan_line_animation.dart    # Artisan — CustomPainter 스캔 라인
        ├── shutter_button.dart         # Artisan — 셔터 버튼
        ├── ocr_processing_overlay.dart # Artisan — 처리 중 오버레이
        ├── ocr_item_card.dart          # Artisan — 인식 항목 카드
        ├── ocr_item_edit_sheet.dart    # Artisan — 인라인 편집 바텀시트
        ├── confidence_badge.dart       # Artisan — "확인 필요" 뱃지
        ├── storage_location_chips.dart # Artisan — 보관 위치 선택 칩
        ├── ocr_success_overlay.dart    # Artisan — 저장 성공 Lottie
        └── retake_guide_view.dart      # Artisan — 재촬영 안내
```
