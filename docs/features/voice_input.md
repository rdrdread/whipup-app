# 음성 재료 입력 (Phase 1.3)

> **Phase:** 1.3
> **선행 조건:** Phase 1.0 완료 (StockItem 모델, Isar 인프라, SubCategoryService)
> **참조 에이전트:** Architect (DTO/Provider), Artisan (음성 UI/피드백 UX), Bridge (speech_to_text/파싱)
> **상위 문서:** `roadmap.md §5`, `product_map.md §6.2`, `screen_layout.md §2.1 (/voice)`
> **병렬 개발:** Phase 1.2(OCR)와 독립적 — 1.0 완료 시 동시 착수 가능

---

## 1. Feature Summary

음성으로 재료를 말하면 `speech_to_text`가 실시간 텍스트로 변환하고,
`VoiceParser`가 자연어를 파싱하여 재고로 등록하는 **손 안 쓰고 재료 등록** 기능.

> **Design Creed 연결:**
> *"가벼운 인터랙션을 지향"* — 젖은 손, 기름진 손으로도 "소고기 300g"이라고 말만 하면 끝.
> *"주방의 소음 속에서도 명확한 전달"* — 시각적 웨이브폼 + 텍스트 실시간 표시 + 인식 성공 시 haptic으로 다각적 피드백.
> *"데이터는 보이지 않게, 즐거움은 눈에 띄게"* — STT 엔진과 NLP 파싱 과정은 웨이브 애니메이션 뒤에 숨기고, 사용자에게는 인식된 재료 카드만 명쾌하게 보여준다.

**음성 입력 파이프라인 요약:**

```
마이크 버튼 탭 (또는 긴 누르기)
    │
    ▼
speech_to_text: 실시간 STT (Streaming)
    │ onResult (partial → final)
    ▼
VoiceParser: 자연어 텍스트 → VoiceItem 목록
    │ "삼겹살 500그램이랑 양파 3개" → [{삼겹살,500,g}, {양파,3,개}]
    ▼
인식 결과 확인/편집 화면 → 사용자 승인
    │
    ▼
StockRepository.add() 일괄 저장
```

---

## 2. User Stories

### US-1: 음성으로 재료 등록
> "장 보고 왔는데 손이 더러우니까 말로 입력하고 싶다."

- **Given:** 재고 목록 화면에서 FAB 더블 탭 또는 AppBar 마이크 아이콘 탭
- **When:** 음성 입력 화면에서 마이크 버튼을 탭하고 "소고기 300그램"이라고 말함
- **Then:** 실시간으로 텍스트가 표시되며, 완료 후 파싱된 재료 항목 카드가 등장
- **And:** `HapticFeedback.lightImpact()` 인식 성공 시 재생

### US-2: 연속 발화로 여러 재료 한번에 등록
> "삼겹살 500그램이랑 양파 3개, 대파 2뿌리 추가해 줘."

- **Given:** 음성 입력 활성화 상태
- **When:** 한 문장에 여러 재료를 말함
- **Then:** VoiceParser가 접속사·쉼표·열거 패턴을 분리하여 복수 VoiceItem 생성
- **And:** 인식된 N개 항목이 카드 목록으로 표시

### US-3: 실시간 부분 인식 피드백
> "내가 뭐라고 말하고 있는지 확인하고 싶다."

- **Given:** 마이크 버튼이 활성화된 상태 (녹음 중)
- **When:** 사용자가 말하는 중
- **Then:** 화면 중앙에 partial recognition 텍스트가 실시간 업데이트
- **And:** 웨이브폼 애니메이션이 음성 볼륨에 반응

### US-4: 인식 결과 편집
> "양파 3개라고 했는데 30개로 인식됐다."

- **Given:** 인식 결과 확인 화면
- **When:** 특정 VoiceItem 카드의 [편집] 버튼 탭
- **Then:** 바텀시트에서 재료명/수량/단위/카테고리 인라인 수정 가능
- **And:** 수정 즉시 반영

### US-5: 인식 실패 재시도
> "소음이 심해서 제대로 못 알아들었다."

- **Given:** STT가 빈 결과 또는 무의미한 텍스트 반환
- **When:** 인식 완료
- **Then:** "다시 한번 말해 주세요" 안내 + [다시 녹음] 버튼 + 팁 표시
- **And:** 팁: "조용한 곳에서", "또박또박", "재료명 위주로"

### US-6: 마이크 권한 요청
> "앱이 마이크를 왜 쓰는지 알고 싶다."

- **Given:** 최초 음성 입력 기능 진입
- **When:** 마이크 권한 미허용 상태
- **Then:** 목적 설명 다이얼로그 표시 후 시스템 권한 요청
- **And:** 거부 시 "설정에서 마이크 권한을 허용해 주세요" 안내 + 설정 이동 버튼

### US-7: 추가 발화 (이어서 말하기)
> "한번에 다 못 말했는데 더 추가하고 싶다."

- **Given:** 1차 인식 완료 후 결과 화면에 항목 N개 표시 중
- **When:** [+ 더 말하기] 버튼 탭 후 추가 발화
- **Then:** 기존 항목 아래에 새로 파싱된 항목이 추가 (누적)
- **And:** 중복 재료명 발생 시 수량 자동 합산 제안 (사용자 승인 필요)

### US-8: 일괄 저장
> "확인 다 했으면 저장하고 싶다."

- **Given:** 결과 확인 화면에서 체크된 항목 1개 이상
- **When:** [N개 재고에 추가하기] CTA 탭
- **Then:** 선택된 VoiceItem이 StockItem으로 변환되어 Isar에 일괄 저장
- **And:** 성공 Lottie + `HapticFeedback.mediumImpact()`
- **And:** 재고 목록 화면으로 이동, 새 항목 상단 하이라이트

---

## 3. Acceptance Criteria

| # | 기준 | 검증 방법 | 에이전트 |
|---|------|----------|---------|
| AC-1 | 마이크 권한 없을 때 목적 설명 후 요청 | 수동 테스트 | Artisan |
| AC-2 | "삼겹살 500그램" → name:"삼겹살", qty:500, unit:"g" 정확 파싱 | Unit Test | Bridge |
| AC-3 | 연속 발화 "A랑 B, C" → 3개 VoiceItem 분리 | Unit Test | Bridge |
| AC-4 | 실시간 partial text 업데이트 (200ms 이내 갱신) | 수동 측정 | Bridge |
| AC-5 | 웨이브폼 애니메이션이 음성 볼륨에 반응 | UI 확인 | Artisan |
| AC-6 | 인식 결과 인라인 편집 (이름/수량/단위/카테고리) | UI 확인 | Artisan |
| AC-7 | [N개 추가하기] 탭 → 선택 항목 Isar 일괄 저장 | Unit Test | Bridge |
| AC-8 | 인식 항목 0개 → 재시도 안내 + 팁 표시 | UI 확인 | Artisan |
| AC-9 | "더 말하기"로 추가 항목 누적 가능 | UI 확인 | Artisan |
| AC-10 | 카테고리 자동 추론 정확도 85% (주요 식재료 기준) | Unit Test | Bridge |
| AC-11 | 녹음 시작/종료 시 haptic 피드백 | UI 확인 | Artisan |
| AC-12 | 배경 소음 과다 시 "조용한 곳에서 시도" 안내 | 수동 테스트 | Bridge |
| AC-13 | 한국어 지원 (ko-KR locale) | Unit Test | Bridge |
| AC-14 | 네트워크 없을 때 에러 안내 (STT는 네트워크 필요) | 수동 테스트 | Bridge |

---

## 4. Data Requirements (Architect)

> 모든 DTO는 Freezed + `fromJson`/`toJson`. `lib/models/`에 위치.

### 4.1. VoiceItem — 음성 인식 단일 항목 DTO

```dart
/// 음성으로 인식된 재료 한 건.
/// VoiceParser가 생성하고, 사용자 확인 후 [StockItem]으로 변환된다.
@freezed
class VoiceItem with _$VoiceItem {
  const VoiceItem._();

  const factory VoiceItem({
    /// 원본 인식 텍스트 조각 (예: "삼겹살 500그램")
    required String rawText,
    /// 정규화된 재료명 (편집 가능)
    required String name,
    /// 수량 (편집 가능)
    @Default(1.0) double quantity,
    /// 단위 (편집 가능, SubCategoryService 자동 추천)
    @Default('개') String unit,
    /// 자동 추론된 카테고리
    StockCategory? category,
    /// 자동 추론된 서브 카테고리
    String? subCategory,
    /// 파서 확신도 0.0~1.0
    @Default(0.0) double confidence,
    /// 사용자 선택 여부 (저장 대상)
    @Default(true) bool isSelected,
  }) = _VoiceItem;

  factory VoiceItem.fromJson(Map<String, dynamic> json) =>
      _$VoiceItemFromJson(json);

  /// VoiceItem → StockItem 변환.
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

### 4.2. VoiceInputState — 음성 입력 세션 상태

```dart
/// 음성 입력 화면의 전체 상태.
@freezed
class VoiceInputState with _$VoiceInputState {
  const factory VoiceInputState({
    /// STT 현재 상태
    @Default(ListeningStatus.idle) ListeningStatus status,
    /// 실시간 partial 텍스트
    @Default('') String partialText,
    /// final 확정 텍스트
    @Default('') String finalText,
    /// 현재 음성 볼륨 레벨 (0.0~1.0, 웨이브폼용)
    @Default(0.0) double soundLevel,
    /// 누적된 인식 항목
    @Default([]) List<VoiceItem> items,
    /// 에러 메시지
    String? error,
  }) = _VoiceInputState;
}
```

### 4.3. ListeningStatus Enum

```dart
enum ListeningStatus {
  idle,       // 대기 중 (마이크 버튼 탭 가능)
  listening,  // 녹음 중 (웨이브폼 활성, partial 업데이트 중)
  processing, // STT 완료 → VoiceParser 파싱 중
  done,       // 결과 표시 중
  error,      // 에러 발생
}
```

### 4.4. MicPermissionStatus Enum

```dart
enum MicPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  undetermined,
}
```

### 4.5. VoiceRepository 인터페이스 (`lib/repositories/voice_repository.dart`)

```dart
/// 음성 인식 및 결과 저장 추상 인터페이스.
abstract class VoiceRepository {
  /// 음성 인식 세션 시작. 결과는 Stream으로 발행.
  Stream<VoiceInputState> startListening();

  /// 음성 인식 세션 중지.
  Future<void> stopListening();

  /// 파싱된 VoiceItem 목록을 StockItem으로 일괄 저장.
  Future<Result<int, AppError>> saveItems({
    required List<VoiceItem> items,
    required StorageLocation location,
  });
}
```

### 4.6. Provider 구조 (`lib/providers/voice_providers.dart`)

| Provider | 타입 | 역할 |
|----------|------|------|
| `micPermissionProvider` | `AsyncNotifier<MicPermissionStatus>` | 마이크 권한 상태 관리 |
| `voiceInputNotifierProvider` | `Notifier<VoiceInputState>` | STT 세션 상태 (listening/partial/final/soundLevel) |
| `voiceItemsNotifierProvider` | `Notifier<List<VoiceItem>>` | 누적 인식 결과 (편집/추가 발화 반영) |
| `selectedVoiceItemsProvider` | `Provider<List<VoiceItem>>` | 저장 대상 필터 (isSelected == true) |
| `voiceSaveProvider` | `AsyncNotifier<int>` | 일괄 저장 실행 및 결과 |

**상태 흐름:**

```
[idle] ─── 마이크 버튼 탭 ───→ [listening]
                                     │ soundLevel 업데이트 (실시간)
                                     │ partialText 업데이트 (실시간)
                                     ▼
                              (발화 종료 감지 또는 수동 종료)
                                     │
                                     ▼
                              [processing] ← VoiceParser 파싱
                                     │
                              ┌──────┴──────┐
                              ▼             ▼
                     [done: items 존재]   [error: 인식 실패]
                              │             │
                      결과 확인 화면     재시도 안내
```

---

## 5. Bridge 설계 (음성 인식 파이프라인)

### 5.1. VoiceInputService (`lib/services/voice_input_service.dart`)

```dart
/// speech_to_text 패키지 래퍼.
/// ⚠ 네트워크 필요 (STT 엔진은 Google/Apple 서버 기반)
abstract class VoiceInputService {
  /// 음성 인식 시작. partial/final 결과를 Stream으로 발행.
  Stream<SpeechResult> listen({required String locale});

  /// 음성 인식 중지.
  Future<void> stop();

  /// 현재 인식 가능 여부 (권한 + 네트워크 + STT 사용 가능)
  Future<bool> isAvailable();

  /// 실시간 사운드 레벨 스트림 (0.0~1.0 정규화)
  Stream<double> soundLevelStream();
}
```

- **패키지:** `speech_to_text: ^7.0.0`
- **언어:** `ko-KR` (한국어), 폴백 `en-US`
- **처리 위치:** Google STT / Apple Speech Framework (네트워크 필요, AC-14)
- **타임아웃:** 발화 종료 감지 후 2초 무음 → 자동 완료
- **최대 녹음 시간:** 60초 (이후 자동 종료 + 결과 파싱)

### 5.2. VoiceParser (`lib/services/voice_parser.dart`)

자연어 텍스트를 `VoiceItem` 목록으로 변환하는 파싱 엔진.

**파싱 단계:**

```
Step 1: 텍스트 정규화
  - 음성 인식 아티팩트 제거 ("어..." "음..." "그..." 필러워드)
  - 숫자 정규화: "오백" → "500", "세" → "3", "한" → "1"
  - 단위 정규화: "그램" → "g", "킬로" → "kg", "밀리리터" → "ml"
  - 전각 → 반각, 불필요한 공백 정리

Step 2: 문장 분리 (Multi-item 처리)
  - 접속사 분리: "랑", "이랑", "하고", "그리고", "또"
  - 열거 패턴: "A, B, C" (쉼표), "A B C" (띄어쓰기 열거)
  - "추가해 줘", "넣어 줘" 등 명령어 접미사 제거

Step 3: 개별 항목 파싱
  - 패턴: [재료명] [수량] [단위]
  - 수량 정규식: r'(\d+(?:\.\d+)?)\s*(g|kg|ml|l|개|묶음|팩|봉|뿌리|캔|병|줄|근|마리)'
  - 수량 없으면: quantity=1, unit='개' 기본값
  - "반근", "한근" → 600g, "한줄" → 1줄 등 관용 표현 매핑

Step 4: 카테고리 추론
  - SubCategoryService 키워드 매핑 재사용 (Phase 1.0과 동일 로직)
  - 매핑 성공 → confidence 0.9
  - 부분 매핑 → confidence 0.6
  - 미매핑 → confidence 0.3

Step 5: 중복 합산 제안
  - 동일 재료명 감지 시 → 합산 제안 VoiceItem 생성
  - 예: "양파 3개" + "양파 2개" → "양파 5개 (합산)" 제안
  - 사용자가 승인/거부 선택
```

**한국어 수량 표현 매핑:**

| 표현 | quantity | unit | 비고 |
|------|----------|------|------|
| "오백그램" | 500 | g | 숫자+단위 직결 |
| "세 개" | 3 | 개 | 고유 수사 |
| "한 근" | 600 | g | 관용 단위 |
| "반 근" | 300 | g | 관용 단위 |
| "두 팩" | 2 | 팩 | 고유 수사 + 외래 단위 |
| "한 뿌리" | 1 | 뿌리 | 대파 등 |
| "서너 개" | 3.5 | 개 | 불확정 수량 → 중간값 + "확인 필요" |
| "조금" / "약간" | 1 | 개 | 정량화 불가 → 기본값 + "확인 필요" |

### 5.3. SpeechResult DTO (Bridge 내부용)

```dart
/// speech_to_text 결과를 내부적으로 래핑하는 DTO.
class SpeechResult {
  final String text;
  final bool isFinal;          // partial(false) vs final(true)
  final double confidence;     // STT 엔진 확신도 0.0~1.0
  
  const SpeechResult({
    required this.text,
    required this.isFinal,
    required this.confidence,
  });
}
```

### 5.4. 에러 핸들링

| 상황 | 처리 |
|------|------|
| 마이크 권한 거부 | 목적 설명 다이얼로그 → 시스템 권한 → 거부 시 설정 안내 |
| 네트워크 없음 | 즉시 에러: "음성 인식은 인터넷이 필요해요" + 와이파이/데이터 확인 안내 |
| STT 엔진 사용 불가 | "음성 인식을 사용할 수 없어요" + 수동 입력 안내 |
| 인식 텍스트 0자 | "말씀하신 내용을 인식하지 못했어요" + 재시도 + 팁 |
| 과다 소음 (soundLevel 지속 높음) | "주변이 너무 시끄러워요" 실시간 안내 배너 |
| 60초 초과 발화 | 자동 종료 + 60초까지 결과 파싱 + "추가로 말하기" 유도 |
| VoiceParser 파싱 결과 0건 | 인식 실패 화면 + 재시도 + 수동 입력 대안 |
| 일괄 저장 중 일부 실패 | 성공 건수 Snackbar + 실패 항목 안내 |

---

## 6. UI Requirements (Artisan)

> 타이포그래피 상세: `design_system.md §1.2.4` 참조.
> 컬러 토큰: 하드코딩 금지, `Theme.of(context)` 사용.
> 터치 타겟: 모든 버튼 최소 48dp.

### 6.1. 화면 구성

#### 6.1.1. 음성 입력 화면 (`/voice`)

```
┌──────────────────────────────┐
│ AppBar: "음성 입력"  [← 닫기]  │
├──────────────────────────────┤
│                              │
│  ┌──────────────────────┐   │
│  │                      │   │  ← 웨이브폼 영역 (120dp 높이)
│  │  ∿∿∿∿ 웨이브폼 ∿∿∿∿  │   │     AudioWaveform (CustomPainter)
│  │                      │   │     soundLevel에 반응하여 진폭 변화
│  └──────────────────────┘   │
│                              │
│  ┌──────────────────────┐   │
│  │ "삼겹살 오백그램이랑" │   │  ← 실시간 텍스트 (bodyLarge, 중앙 정렬)
│  │  ← partial (흐린색)  │   │     partial: onSurfaceVariant
│  └──────────────────────┘   │     final: onSurface (진한 색)
│                              │
│  상태별 힌트 텍스트:          │  ← bodyMedium, onSurfaceVariant
│  idle: "마이크를 탭하고        │
│        재료를 말해 주세요"     │
│  listening: "듣고 있어요..."   │
│  processing: "재료를 정리 중..." │
│                              │
│                              │
│        🎙 (68dp)             │  ← MicButton (idle: Primary, 녹음중: dangerRed)
│                              │     녹음 중 → 맥박 애니메이션 (pulse ring)
│                              │
│   수동으로 입력하기            │  ← TextButton → /stock/add
│                              │
└──────────────────────────────┘
```

#### 6.1.2. 인식 결과 확인 화면 (`/voice/review`)

```
┌──────────────────────────────┐
│ AppBar: "인식 결과"  [+ 더 말하기] │
├──────────────────────────────┤
│ 저장할 재고함                  │
│ [🧊냉장고✓] [❄️냉동고] [📦팬트리]│  ← 보관 위치 선택 칩
├──────────────────────────────┤
│ 🎤 3개 인식됨                 │  ← titleMedium
│ (체크 해제하면 저장 제외됩니다)   │  ← bodySmall
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ ✅ 🥩 삼겹살    500g [편집]│ │  ← VoiceItemCard (선택됨)
│ ├──────────────────────────┤ │
│ │ ✅ 🥬 양파     3개  [편집]│ │
│ ├──────────────────────────┤ │
│ │ ⚠ ✅ 대파     2뿌리[편집]│ │  ← "확인 필요" (비표준 단위)
│ └──────────────────────────┘ │
│                              │
│ ┌──────────────────────────┐ │
│ │ [3개 재고에 추가하기]   CTA│ │  ← Filled Button, Primary
│ └──────────────────────────┘ │
├──────────────────────────────┤
│ [홈] [재고] [레시피] [마이]    │
└──────────────────────────────┘
```

#### 6.1.3. 인식 실패 안내

```
┌──────────────────────────────┐
│ AppBar: "음성 입력"             │
├──────────────────────────────┤
│                              │
│      🎤❓                     │  ← 이모지 64dp
│                              │
│  말씀하신 내용을 인식하지       │  ← headlineSmall
│  못했어요                     │
│                              │
│  인식 팁                      │  ← titleSmall
│  • 조용한 곳에서 시도하세요    │
│  • 또박또박 말해 주세요        │  ← bodyMedium
│  • "재료명 + 수량"으로 말하면  │
│    더 정확해요                 │
│  • 예: "삼겹살 오백그램"       │  ← bodyMedium + Primary 색상
│                              │
│ ┌──────────────────────────┐ │
│ │     [다시 녹음]    CTA    │ │
│ └──────────────────────────┘ │
│                              │
│      수동으로 입력하기          │  ← TextButton → /stock/add
│                              │
└──────────────────────────────┘
```

### 6.2. 위젯 목록

| 위젯 | 위치 | 역할 |
|------|------|------|
| `AudioWaveform` | `/voice` | 음성 볼륨 반응 웨이브폼 (CustomPainter) |
| `MicButton` | `/voice` | 68dp 마이크 버튼 (idle: Primary, recording: Red + pulse) |
| `PulseRing` | MicButton 내부 | 녹음 중 원형 맥박 애니메이션 (0→68→0dp, 1.5초 루프) |
| `PartialTextDisplay` | `/voice` | 실시간 텍스트 표시 (partial 흐림, final 진함) |
| `ListeningStatusHint` | `/voice` | 상태별 안내 텍스트 (idle/listening/processing) |
| `VoiceItemCard` | `/voice/review` | 인식 항목 1건: 체크+이모지+이름+수량+편집 |
| `VoiceItemEditSheet` | VoiceItemCard 탭 | 바텀시트 인라인 편집 |
| `ConfidenceBadge` | VoiceItemCard 내부 | "확인 필요 ⚠" 뱃지 (confidence < 0.6) |
| `MergeProposalCard` | `/voice/review` | 중복 합산 제안 카드 (승인/거부) |
| `StorageLocationChips` | `/voice/review` 상단 | 보관 위치 선택 칩 (OCR 화면과 공유) |
| `VoiceSuccessOverlay` | 저장 완료 | 성공 Lottie (1.5초 → 재고 목록) |
| `RetryGuideView` | 인식 실패 | 재시도 안내 + 팁 + 수동 입력 |
| `NoiseWarningBanner` | `/voice` 상단 | 소음 과다 실시간 경고 배너 |

### 6.3. 상호작용 및 애니메이션

| 이벤트 | 효과 | 타이밍 |
|--------|------|--------|
| 마이크 버튼 탭 (녹음 시작) | `mediumImpact()` + 버튼 Primary→Red (200ms) + PulseRing 시작 | 즉시 |
| 마이크 버튼 탭 (녹음 종료) | `lightImpact()` + 버튼 Red→Primary (200ms) + PulseRing 종료 | 즉시 |
| Partial 텍스트 업데이트 | 텍스트 페이드인 (100ms) | 실시간 |
| 최종 텍스트 확정 | `lightImpact()` + 텍스트 색상 변경 (200ms) | STT final |
| 파싱 결과 등장 | VoiceItemCard 슬라이드업 stagger (80ms 간격) | 파싱 완료 후 |
| VoiceItemCard 체크 토글 | `selectionClick()` + 체크 스케일 팝 | 즉시 |
| 합산 제안 등장 | MergeProposalCard 슬라이드 다운 (200ms) | 중복 감지 |
| 저장 완료 | `mediumImpact()` + 성공 Lottie (1.5초) | 저장 완료 즉시 |
| 소음 경고 | NoiseWarningBanner 슬라이드 다운 (300ms, warningAmber) | soundLevel > 0.8 지속 3초 |
| 웨이브폼 진동 | 사인파 진폭 = soundLevel × maxAmplitude (실시간) | 프레임 단위 |

### 6.4. 타이포그래피 매핑

| 요소 | 스타일 | 예시 |
|------|--------|------|
| AppBar 제목 | `titleLarge` (20sp SemiBold) | "음성 입력" |
| 인식 중 텍스트 (partial) | `bodyLarge` + onSurfaceVariant | "삼겹살 오백..." |
| 인식 완료 텍스트 (final) | `bodyLarge` + onSurface | "삼겹살 오백그램이랑" |
| 상태 힌트 | `bodyMedium` + onSurfaceVariant | "마이크를 탭하고 재료를 말해 주세요" |
| 인식 항목 수 헤더 | `titleMedium` | "🎤 3개 인식됨" |
| VoiceItemCard 재료명 | `titleSmall` | "삼겹살" |
| VoiceItemCard 수량·단위 | `bodyMedium` | "500g" |
| 확인 필요 뱃지 | `labelSmall` + warningAmber | "확인 필요 ⚠" |
| 저장 CTA | `labelLarge` | "3개 재고에 추가하기" |
| 실패 안내 제목 | `headlineSmall` | "인식하지 못했어요" |
| 팁 항목 | `bodyMedium` | "또박또박 말해 주세요" |
| 소음 경고 | `labelLarge` + warningAmber | "주변이 시끄러워요 🔊" |

### 6.5. 진입점

| 진입 경로 | 트리거 |
|----------|--------|
| 재고 목록 AppBar의 마이크 아이콘 | 아이콘 탭 |
| 재고 추가 화면의 [음성 입력] 버튼 | 버튼 탭 |
| 홈 대시보드의 "음성으로 추가" 퀵 액션 (Phase 1.3+) | 카드 탭 |
| FAB 더블 탭 (재고 목록 화면) | 더블 탭 제스처 |

---

## 7. Edge Cases

| 상황 | 처리 |
|------|------|
| 마이크 권한 영구 거부 | "설정에서 마이크 권한을 허용해 주세요" + 설정 이동 버튼 |
| 네트워크 없음 | "음성 인식은 인터넷이 필요해요" 즉시 안내 + 수동 입력 대안 |
| 발화 없이 10초 무음 | 자동 종료 + "아무 소리도 들리지 않았어요" |
| 60초 초과 연속 발화 | 자동 종료 + 60초분 결과 파싱 + "더 말하기" 유도 |
| 재료명 아닌 일상어 ("오늘 뭐 먹지") | 파싱 결과 0건 → 인식 실패 화면 |
| 불확정 수량 ("서너 개", "조금") | 중간값 + "확인 필요" 뱃지 |
| 동일 재료 중복 발화 | MergeProposalCard로 합산 제안 (사용자 승인/거부) |
| 영어 재료명 ("아보카도", "파스타") | 한국어화된 외래어는 정상 매핑. 순수 영어 → confidence 0.3 |
| 사투리/비표준 표현 ("양배추" vs "양배기") | STT 엔진 처리에 의존 → 인식 실패 시 수동 편집 유도 |
| 배경 음악·TV 소음 | NoiseWarningBanner 실시간 표시 + 녹음은 계속 (STT가 필터링) |
| "전부 취소" / "다 지워줘" 음성 명령 | Phase 1.3에서 미지원 → 텍스트로 파싱 시도 (미매칭은 인식 실패 처리) |

---

## 8. OCR과의 공통 컴포넌트

Phase 1.2(OCR)와 Phase 1.3(음성)은 동일한 패턴을 공유한다.
재사용 가능한 위젯과 로직은 `widgets/common/` 또는 상위 provider로 추출한다.

| 컴포넌트 | 공유 여부 | 위치 |
|---------|----------|------|
| `StorageLocationChips` | ✅ 공유 | `widgets/common/` |
| `ConfidenceBadge` | ✅ 공유 | `widgets/common/` |
| `SuccessOverlay` (성공 Lottie) | ✅ 공유 | `widgets/common/` |
| Item → StockItem 변환 로직 | ✅ 유사 (DTO 자체 메서드) | 각 `VoiceItem`, `OcrItem` |
| 카테고리 키워드 매핑 | ✅ 재사용 | `SubCategoryService` (Phase 1.0) |
| 일괄 저장 Provider 패턴 | ✅ 유사 | 각 `voice_providers`, `ocr_providers` |
| 편집 바텀시트 | ⚠ 구조 유사 | `VoiceItemEditSheet` / `OcrItemEditSheet` (별도) |

---

## 9. 선행 조건 및 의존성

```
Phase 1.0 (재고 관리)
└── StockItem 모델, StockCategory/StorageLocation enum
    SubCategoryService (키워드 → 카테고리 매핑 재사용)
    StockRepository.add() (일괄 저장)
    Isar 인프라

Phase 1.3 (본 문서)
├── Architect: VoiceItem, VoiceInputState DTO, ListeningStatus enum
│             VoiceRepository 인터페이스, 5 Riverpod Providers
├── Bridge:   VoiceInputService (speech_to_text 래퍼, STT streaming)
│             VoiceParser (자연어 → VoiceItem 파싱, 한국어 수량 정규화)
└── Artisan:  /voice + /voice/review 화면
              AudioWaveform, MicButton, PulseRing, VoiceItemCard 등 위젯

Phase 1.2 (OCR) — 병렬 개발 (공통 컴포넌트 §8 참조)
Phase 2.0+ — 서버에 음성 인식 로그 전송하여 파싱 모델 개선 가능
```

---

## 10. 파일 구조

```
app/lib/
├── models/
│   ├── voice_item.dart                # Architect — VoiceItem Freezed DTO
│   ├── voice_input_state.dart         # Architect — VoiceInputState Freezed
│   ├── listening_status.dart          # Architect — enum
│   └── mic_permission_status.dart     # Architect — enum
│
├── repositories/
│   ├── voice_repository.dart                  # Architect — interface
│   └── impl/
│       └── stt_voice_repository.dart          # Bridge — implementation
│
├── providers/
│   └── voice_providers.dart           # Architect — 5 providers
│
├── services/
│   ├── voice_input_service.dart       # Bridge — speech_to_text 래퍼
│   └── voice_parser.dart              # Bridge — 자연어 → VoiceItem 파싱
│
├── views/
│   └── voice/
│       ├── voice_screen.dart          # Artisan — 음성 입력 메인
│       └── voice_review_screen.dart   # Artisan — 인식 결과 확인
│
└── widgets/
    ├── common/                        # Phase 1.2/1.3 공유
    │   ├── storage_location_chips.dart
    │   ├── confidence_badge.dart
    │   └── success_overlay.dart
    └── voice/
        ├── audio_waveform.dart        # Artisan — CustomPainter 웨이브폼
        ├── mic_button.dart            # Artisan — 마이크 버튼 + 상태 색상
        ├── pulse_ring.dart            # Artisan — 녹음 중 맥박 애니메이션
        ├── partial_text_display.dart  # Artisan — 실시간 텍스트 표시
        ├── listening_status_hint.dart # Artisan — 상태별 안내 텍스트
        ├── voice_item_card.dart       # Artisan — 인식 항목 카드
        ├── voice_item_edit_sheet.dart # Artisan — 편집 바텀시트
        ├── merge_proposal_card.dart   # Artisan — 중복 합산 제안 카드
        ├── noise_warning_banner.dart  # Artisan — 소음 경고 배너
        └── retry_guide_view.dart      # Artisan — 재시도 안내
```
