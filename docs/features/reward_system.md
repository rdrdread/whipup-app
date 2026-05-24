# 리워드 시스템 (Phase 1.4)

> **Phase:** 1.4
> **선행 조건:** Phase 1.0 (재고 관리) + Phase 1.1 (AI 레시피 추천) 완료
> **참조 에이전트:** Architect (모델/Provider), Artisan (UI/애니메이션), Bridge (트리거 서비스/Isar)
> **상위 문서:** `roadmap.md §6`, `design_system.md §6 (Micro-Interactions)`, `brand-assets §2.1`

---

## 1. Feature Summary

요리 활동(재고 등록, 레시피 완료, OCR/음성 입력, 연속 사용 등)에 보상을 부여하여
사용자의 지속적 사용 동기를 강화하고, **"요리가 즐거운 창작"** 이라는 브랜드 가치를 체험하게 하는 동기 부여 시스템.

> **핵심 철학:** 보상은 '강요'가 아니라 **'발견의 기쁨'**.
> 사용자가 뭔가를 하고 있다는 사실을 잊었을 때 뱃지가 툭 나타나는 설계.
> 윕업 톤(따뜻함·즐거움·잔소리 금지)을 철저히 유지한다.

> **Design Creed 연결 (`design_system.md §6`):**
> - *Progressive Rewards* — 조리 단계 완료마다 진행 바에 불꽃 애니메이션. 전체 완료 시 `success` Lottie.
> - *Ingredient Vanishing Effect* — 재료 소진 제스처 시 Dust Effect로 '해치웠다'는 쾌감.
> - *Sound Identity* — 업적 달성 시 `recipe_complete.wav`, 연속 기록 경보 시 `expiry_alert.wav`.

**전체 보상 구조:**

```
활동 이벤트 발생
    │
    ▼
RewardTriggerService (이벤트 감지)
    │
    ├── AchievementChecker: 업적 조건 충족 여부 검사
    │       └── 달성 → Achievement.unlockedAt 기록 → Isar 저장
    │
    └── StatsUpdater: 활동 통계 갱신 (totalRecipes++, streak 계산)
            └── Isar 저장 → Provider Stream 갱신 → UI 반영
```

---

## 2. User Stories

### US-1: 업적 자동 달성
> "첫 레시피를 완료했더니 '첫 요리사' 뱃지가 툭 나타났다!"

- **Given:** 사용자가 레시피 조리 완료 표시
- **When:** `RewardTriggerService`가 `recipeCompleted` 이벤트 처리
- **Then:** `first_recipe` 업적 조건 충족 시 `AchievementPopup` 모달 표시
- **And:** `HapticFeedback.mediumImpact()` + `recipe_complete.wav` + 축하 Lottie

### US-2: 연속 기록 마일스톤
> "7일 연속으로 요리를 기록했다."

- **Given:** `currentStreak`가 7에 도달
- **When:** 당일 첫 번째 활동 기록 시
- **Then:** `streak_7` 업적 달성 팝업 + 특별 뱃지 (🌟)
- **And:** `displaySmall` 크기의 숫자 카운터 팝업 (`"7일 🌟"`)

### US-3: 리워드 대시보드 탐색
> "내가 모은 뱃지와 기록을 한눈에 보고 싶다."

- **Given:** `/my/reward` 진입
- **When:** 화면 로드
- **Then:** 연속 기록 카드 + 활동 통계 3개 + 업적 그리드 표시
- **And:** 미달성 업적은 잠금 처리(흐린 이모지 + 자물쇠) + 힌트 메시지 표시

### US-4: 업적 상세 보기
> "이 뱃지를 어떻게 얻었는지 알고 싶다."

- **Given:** 업적 그리드에서 특정 카드 탭
- **When:** AchievementDetailSheet 바텀시트 팝업
- **Then:** 업적 이모지 + 이름 + 달성 조건 + 달성 일시 표시
- **And:** 미달성이면 "남은 조건: N회 더 필요해요" 표시

### US-5: 제로 웨이스트 달성
> "7일 내내 유통기한 초과 재료 없이 유지했다."

- **Given:** `zero_waste` 조건 충족 (유통기한 초과 재료 0개 × 7일)
- **When:** 매일 앱 진입 시 `RewardTriggerService` 검사
- **Then:** `zero_waste` 업적 달성 + `🌱` 뱃지
- **And:** "7일 동안 낭비 없이 요리했어요! 지구도 기뻐해요 🌍" 메시지

### US-6: Phase 1.2/1.3 연동 업적
> "영수증을 처음 찍었더니 뱃지가 생겼다."

- **Given:** OCR 영수증 인식 성공 후 첫 저장
- **When:** `ocrItemsSaved` 이벤트 처리
- **Then:** `first_ocr` 업적 달성
- **And:** 음성 입력 첫 성공 시 `first_voice` 업적 달성

### US-7: 진행 중 업적 힌트
> "다음 뱃지가 뭔지 궁금하다."

- **Given:** 리워드 대시보드의 미달성 업적 카드
- **When:** 카드 탭
- **Then:** 달성까지 남은 조건 표시 ("레시피 3회 더 완료하면 '요리 입문자' 획득!")
- **And:** 진행률 바 표시 (해당하는 업적에 한해)

---

## 3. Achievement 목록

### 3.1. 재고 관련

| ID | 이름 | 조건 | 이모지 | 트리거 이벤트 |
|----|------|------|--------|------------|
| `first_stock` | 첫 재료 등록 | StockItem 1개 등록 | 🥬 | `stockAdded` |
| `stock_10` | 재고 채우기 | 재고 10개 이상 동시 보유 | 🧺 | `stockAdded` |
| `zero_waste` | 제로 웨이스트 | 유통기한 초과 재료 0개 × 7일 연속 | 🌱 | `appOpened` (일별) |
| `first_ocr` | 영수증 스캐너 | OCR 영수증 첫 스캔 성공 | 📄 | `ocrItemsSaved` |
| `first_voice` | 말로 하는 장보기 | 음성 입력 첫 성공 | 🎤 | `voiceItemsSaved` |
| `multi_input` | 멀티 인풋 마스터 | 수동·OCR·음성 3가지 방식 모두 사용 | 🎯 | 각 저장 이벤트 |

### 3.2. 레시피 관련

| ID | 이름 | 조건 | 이모지 | 트리거 이벤트 |
|----|------|------|--------|------------|
| `first_recipe` | 첫 요리사 | 레시피 완료 1회 | 👨‍🍳 | `recipeCompleted` |
| `recipe_5` | 요리 입문자 | 레시피 완료 5회 | 🍳 | `recipeCompleted` |
| `recipe_20` | 요리 매니아 | 레시피 완료 20회 | 🔥 | `recipeCompleted` |
| `recipe_50` | 요리 장인 | 레시피 완료 50회 | 🏅 | `recipeCompleted` |
| `explorer` | 탐험가 | 5개 이상 recipe_type 시도 | 🗺️ | `recipeCompleted` |
| `all_types` | 풀코스 마스터 | 모든 recipe_type 1회 이상 완료 | 🍽️ | `recipeCompleted` |

### 3.3. 연속 기록

| ID | 이름 | 조건 | 이모지 | 트리거 이벤트 |
|----|------|------|--------|------------|
| `streak_3` | 3일 연속 | 3일 연속 활동 | ⭐ | `appOpened` (일별) |
| `streak_7` | 일주일 연속 | 7일 연속 활동 | 🌟 | `appOpened` (일별) |
| `streak_14` | 2주 연속 | 14일 연속 활동 | 💫 | `appOpened` (일별) |
| `streak_30` | 한 달 연속 | 30일 연속 활동 | 🏆 | `appOpened` (일별) |

### 3.4. 콘텐츠 (Phase 2.6 이후 활성화)

| ID | 이름 | 조건 | 이모지 | 트리거 이벤트 |
|----|------|------|--------|------------|
| `column_reader` | 호기심 독자 | 칼럼 5편 읽기 | 📚 | `columnRead` |
| `science_fan` | 식품 과학자 | 과학 칼럼 3편 읽기 | 🔬 | `columnRead` |

---

## 4. Data Requirements (Architect)

> 모든 모델은 Freezed + `fromJson`/`toJson`. `lib/models/`에 위치.

### 4.1. Achievement 모델 (`lib/models/achievement.dart`)

```dart
/// 업적 한 건. 정적 정의(seed) + 동적 달성 상태를 통합.
@freezed
class Achievement with _$Achievement {
  const Achievement._();

  const factory Achievement({
    /// 업적 고유 ID (예: 'first_recipe')
    required String id,
    /// 업적 이름
    required String title,
    /// 달성 조건 설명
    required String description,
    /// 대표 이모지
    required String emoji,
    /// 달성 시각 (null = 미달성)
    DateTime? unlockedAt,
    /// 달성 조건 정의
    required AchievementCondition condition,
    /// 진행률 표시 여부 (횟수 기반 업적에만 true)
    @Default(false) bool showProgress,
    /// Phase 2.6 이전 비활성화 여부
    @Default(false) bool isLocked,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);

  /// 달성 여부
  bool get isUnlocked => unlockedAt != null;

  /// 진행률 계산 (0.0~1.0). [currentCount] 는 Bridge가 제공.
  double progress(int currentCount) {
    final target = condition.targetCount;
    if (target == null || target == 0) return isUnlocked ? 1.0 : 0.0;
    return (currentCount / target).clamp(0.0, 1.0);
  }
}
```

### 4.2. AchievementCondition 모델 (`lib/models/achievement_condition.dart`)

```dart
/// 업적 달성 조건 — 이벤트 타입 + 임계값.
@freezed
class AchievementCondition with _$AchievementCondition {
  const factory AchievementCondition({
    /// 감지할 이벤트 타입
    required RewardEventType eventType,
    /// 달성에 필요한 횟수/일수 (null = 1회 이벤트 발생으로 달성)
    int? targetCount,
    /// 특정 recipe_type 제한 (null = 전체)
    String? recipeTypeFilter,
  }) = _AchievementCondition;

  factory AchievementCondition.fromJson(Map<String, dynamic> json) =>
      _$AchievementConditionFromJson(json);
}
```

### 4.3. RewardEventType Enum (`lib/models/reward_event_type.dart`)

```dart
/// RewardTriggerService가 감지하는 이벤트 유형.
enum RewardEventType {
  stockAdded,          // 재고 1건 추가
  recipeCompleted,     // 레시피 완료 표시
  ocrItemsSaved,       // OCR 영수증 재고 저장
  voiceItemsSaved,     // 음성 입력 재고 저장
  appOpened,           // 앱 진입 (streak·zero_waste 일별 체크)
  columnRead,          // 칼럼 1편 읽기 완료 (Phase 2.6)
}
```

### 4.4. UserRewardStats 모델 (`lib/models/user_reward_stats.dart`)

```dart
/// 사용자의 활동 통계 전체.
@freezed
class UserRewardStats with _$UserRewardStats {
  const UserRewardStats._();

  const factory UserRewardStats({
    /// 총 레시피 완료 횟수
    @Default(0) int totalRecipesCompleted,
    /// 현재 연속 활동 일수
    @Default(0) int currentStreak,
    /// 역대 최장 연속 일수
    @Default(0) int longestStreak,
    /// 시도한 고유 recipe_type 집합
    @Default({}) Set<String> uniqueRecipeTypes,
    /// 누적 재고 등록 수 (OCR·음성·수동 합산)
    @Default(0) int totalStocksAdded,
    /// OCR 사용 횟수
    @Default(0) int ocrUseCount,
    /// 음성 입력 사용 횟수
    @Default(0) int voiceUseCount,
    /// 마지막 활동 일자 (UTC date, 시간 제외)
    DateTime? lastActivityDate,
    /// 읽은 칼럼 ID 목록
    @Default([]) List<String> readColumnIds,
  }) = _UserRewardStats;

  factory UserRewardStats.fromJson(Map<String, dynamic> json) =>
      _$UserRewardStatsFromJson(json);

  /// 연속 기록 계산용 — 어제 활동 여부
  bool get wasActiveYesterday {
    if (lastActivityDate == null) return false;
    final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));
    return lastActivityDate!.year == yesterday.year &&
        lastActivityDate!.month == yesterday.month &&
        lastActivityDate!.day == yesterday.day;
  }

  /// 오늘 이미 활동했는지 여부 (streak 중복 카운트 방지)
  bool get wasActiveToday {
    if (lastActivityDate == null) return false;
    final today = DateTime.now().toUtc();
    return lastActivityDate!.year == today.year &&
        lastActivityDate!.month == today.month &&
        lastActivityDate!.day == today.day;
  }
}
```

### 4.5. RewardRepository 인터페이스 (`lib/repositories/reward_repository.dart`)

```dart
/// 업적 및 통계 영속화 추상 인터페이스.
abstract class RewardRepository {
  /// 전체 업적 목록 (seed + 달성 상태 병합)
  Future<Result<List<Achievement>, AppError>> getAllAchievements();

  /// 특정 업적 달성 처리
  Future<Result<void, AppError>> unlockAchievement(String achievementId);

  /// 사용자 통계 조회
  Future<Result<UserRewardStats, AppError>> getStats();

  /// 사용자 통계 갱신
  Future<Result<void, AppError>> updateStats(UserRewardStats stats);

  /// 통계 실시간 감시 Stream
  Stream<UserRewardStats> watchStats();

  /// 달성된 업적 실시간 감시 Stream (새 달성 시 emit)
  Stream<Achievement> watchNewlyUnlocked();
}
```

### 4.6. Provider 구조 (`lib/providers/reward_providers.dart`)

| Provider | 타입 | 역할 |
|----------|------|------|
| `rewardStatsProvider` | `StreamProvider<UserRewardStats>` | 통계 실시간 감시 |
| `achievementsProvider` | `AsyncNotifier<List<Achievement>>` | 전체 업적 목록 (달성 상태 포함) |
| `newlyUnlockedProvider` | `StreamProvider<Achievement>` | 방금 달성한 업적 → AchievementPopup 트리거 |
| `rewardTriggerProvider` | `Provider<RewardTriggerService>` | 이벤트 처리 서비스 인스턴스 |
| `streakDisplayProvider` | `Provider<StreakDisplay>` | 연속 기록 표시용 파생 데이터 (아이콘·색상·메시지) |

---

## 5. Bridge 설계 (트리거 & 영속화)

### 5.1. RewardTriggerService (`lib/services/reward_trigger_service.dart`)

```dart
/// 앱 전역 이벤트를 수신하여 업적·통계를 갱신하는 오케스트레이터.
/// 모든 이벤트는 단방향: Provider → TriggerService → Repository.
abstract class RewardTriggerService {
  /// 이벤트 발생 알림. 각 Provider가 관련 작업 완료 후 호출.
  Future<void> dispatch(RewardEvent event);
}

/// 이벤트 페이로드.
@freezed
class RewardEvent with _$RewardEvent {
  const factory RewardEvent({
    required RewardEventType type,
    /// 이벤트 관련 부가 정보
    Map<String, dynamic>? payload,
    /// 이벤트 발생 시각
    required DateTime occurredAt,
  }) = _RewardEvent;
}
```

**dispatch 처리 흐름:**

```
dispatch(RewardEvent) 호출
    │
    ├── 1. StatsUpdater.update(event)
    │       ├── totalStocksAdded++ (stockAdded 시)
    │       ├── totalRecipesCompleted++ (recipeCompleted 시)
    │       ├── uniqueRecipeTypes에 recipeType 추가
    │       ├── streak 계산 (appOpened 시)
    │       │     ├── wasActiveToday → 스킵
    │       │     ├── wasActiveYesterday → currentStreak++
    │       │     └── 그 외 → currentStreak = 1 (오늘 첫 활동)
    │       │           longestStreak = max(current, longest)
    │       └── Isar 저장 → watchStats() 스트림 갱신
    │
    └── 2. AchievementChecker.check(event, stats)
            ├── 이 이벤트와 관련된 Achievement 후보 조회
            ├── 각 후보의 조건 충족 여부 검사
            │     ├── 이미 달성됨 → 스킵
            │     └── 조건 충족 → unlockAchievement()
            │                    → watchNewlyUnlocked() emit
            └── 완료
```

### 5.2. AchievementChecker (`lib/services/achievement_checker.dart`)

```dart
/// 이벤트 타입별 업적 조건 검사.
abstract class AchievementChecker {
  /// 이벤트 발생 후 갱신된 [stats]를 기준으로 업적 조건 검사.
  Future<List<Achievement>> checkAndUnlock({
    required RewardEvent event,
    required UserRewardStats stats,
    required List<Achievement> allAchievements,
  });
}
```

**조건 검사 로직:**

| 업적 | 검사 조건 |
|------|----------|
| `first_stock` | `stats.totalStocksAdded >= 1` |
| `stock_10` | 현재 Isar에서 `StockItem` 개수 조회 ≥ 10 |
| `zero_waste` | `appOpened` 이벤트 시, 유통기한 초과 재료 0개 × 7일 카운터 검사 |
| `first_ocr` | `stats.ocrUseCount >= 1` |
| `first_voice` | `stats.voiceUseCount >= 1` |
| `multi_input` | `ocrUseCount >= 1 && voiceUseCount >= 1 && (totalStocksAdded - ocrUseCount - voiceUseCount) >= 1` |
| `recipe_5` | `stats.totalRecipesCompleted >= 5` |
| `explorer` | `stats.uniqueRecipeTypes.length >= 5` |
| `streak_7` | `stats.currentStreak >= 7` |

### 5.3. Isar 컬렉션 (`lib/repositories/impl/isar_reward_repository.dart`)

**IsarAchievement:**

```dart
@collection
class IsarAchievement {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, unique: true)
  late String achievementId;          // 'first_recipe' 등
  DateTime? unlockedAt;               // null = 미달성
}
```

**IsarUserRewardStats:**

```dart
@collection
class IsarUserRewardStats {
  Id id = 1;                          // 단일 레코드 (싱글톤)
  late int totalRecipesCompleted;
  late int currentStreak;
  late int longestStreak;
  late List<String> uniqueRecipeTypes;
  late int totalStocksAdded;
  late int ocrUseCount;
  late int voiceUseCount;
  DateTime? lastActivityDate;
  late List<String> readColumnIds;
}
```

### 5.4. 연속 기록 계산 상세

```
매일 앱 첫 진입 시 appOpened 이벤트 dispatch:

오늘 이미 활동함 (wasActiveToday)?
  └── YES → 스킵 (중복 카운트 방지)
  └── NO →
        어제 활동했음 (wasActiveYesterday)?
          └── YES → currentStreak += 1
                    longestStreak = max(currentStreak, longestStreak)
          └── NO →  currentStreak = 1 (오늘 새로 시작)
        lastActivityDate = today (UTC 00:00:00)
```

- **날짜 기준:** UTC 자정 (타임존 이슈 방지)
- **활동 정의:** 앱 진입만으로 streak 인정 (레시피 완료 불필요 — 진입 장벽 최소화)
- **streak 초기화:** 어제도 오늘도 활동 없으면 다음 날 진입 시 1로 리셋

### 5.5. 에러 핸들링

| 상황 | 처리 |
|------|------|
| Isar 저장 실패 | `AppError.database()` 반환, 팝업 억제 (소리없이 스킵) |
| 동일 업적 중복 dispatch | `isUnlocked == true` 체크 후 스킵 |
| stats 조회 실패 | 기본값 `UserRewardStats()` 반환 |
| 앱 삭제 후 재설치 | 로컬 초기화 (Phase 2.0+ 서버 동기화로 복원) |
| 날짜 조작 감지 | 미대응 (Phase 1.4 범위 외) |

---

## 6. UI Requirements (Artisan)

> 타이포그래피: `design_system.md §1.2.4 (리워드)` 기준.
> 컬러 토큰: 하드코딩 금지. `brand-assets §2.1` Primary/Secondary/Semantic 색상 사용.
> 모든 터치 타겟 최소 48dp.

### 6.1. 리워드 대시보드 (`/my/reward`)

```
┌──────────────────────────────┐
│ AppBar: "나의 기록"            │
├──────────────────────────────┤
│                              │
│ ┌──────────────────────────┐ │
│ │  🔥 현재 7일 연속!         │ │  ← StreakCard (Flame Orange 그라데이션)
│ │   ━━━━━━━━━━━━━━━━━━━    │ │     숫자: displaySmall (26sp Bold)
│ │  [월][화][수][목][금][토][일] │ │     요일 도트: 완료=Primary, 미완=surfaceVariant
│ │   최장 기록: 14일          │ │
│ └──────────────────────────┘ │
│                              │
│ 📊 활동 통계                  │
│ ┌───────┐ ┌───────┐ ┌──────┐ │
│ │  12   │ │  35   │ │  4   │ │  ← 숫자: displaySmall
│ │ 총 요리 │ │ 등록재료 │ │ 레시피 │ │     라벨: bodySmall
│ └───────┘ └───────┘ └──────┘ │
│ ┌───────┐ ┌───────┐          │
│ │   3   │ │   2   │          │
│ │OCR사용│ │음성사용│          │
│ └───────┘ └───────┘          │
│                              │
│ 🏆 업적                      │
│ ┌──────────────────────────┐ │
│ │ [👨‍🍳] [🍳] [⭐] [🌱] [📄] │ │  ← 달성: 컬러 이모지 (48dp)
│ │ [ 🗺️] [🏅] [🌟] [💫] ...│ │  ← 미달성: 흐린 이모지 + 자물쇠 🔒
│ │ (3열 그리드, 탭 → 상세)    │ │
│ └──────────────────────────┘ │
│                              │
└──────────────────────────────┘
```

### 6.2. 업적 달성 팝업 (전체 화면 오버레이)

```
┌──────────────────────────────┐
│ [반투명 스크림 배경 — 탭으로 닫기]│
│                              │
│   ╔══════════════════════╗   │
│   ║                      ║   │
│   ║  [축하 Lottie 전체]   ║   │  ← confetti.json 또는 success.json
│   ║                      ║   │
│   ║        🏆            ║   │  ← 이모지 72dp, 스케일 팝 (0.5→1.2→1.0)
│   ║                      ║   │
│   ║   업적 달성!           ║   │  ← headlineSmall
│   ║   한 달 연속           ║   │  ← titleMedium
│   ║   30일 연속 요리를 기록  ║   │  ← bodyMedium
│   ║   했어요. 대단해요! 🎉  ║   │
│   ║                      ║   │
│   ║   [달성일: 2026.05.24]  ║   │  ← bodySmall + onSurfaceVariant
│   ║                      ║   │
│   ║  [확인]  Filled Button ║   │
│   ╚══════════════════════╝   │
└──────────────────────────────┘
```

- **진입 애니메이션:** 카드 스케일 0→1 (300ms, ElasticOut)
- **이모지 팝:** 스케일 0.5→1.2→1.0 (500ms, Bounce)
- **배경 스크림:** `Colors.black54`, 탭하면 닫힘
- **자동 닫힘:** 없음 (사용자가 직접 [확인] 탭)

### 6.3. 업적 상세 바텀시트

```
┌──────────────────────────────┐
│         ─── (드래그 핸들)      │
│                              │
│   👨‍🍳  첫 요리사              │  ← 이모지 56dp + titleMedium
│                              │
│   레시피를 처음 완료했어요!      │  ← bodyMedium
│   ─────────────────          │
│   달성 조건: 레시피 완료 1회    │  ← bodySmall + onSurfaceVariant
│   달성 일시: 2026.05.01        │  ← bodySmall + onSurfaceVariant
│                              │
│  ─── [미달성인 경우] ───────   │
│   🔒  요리 입문자             │
│                              │
│   레시피 완료 5회              │
│   ┌──────────────────────┐  │
│   │ ████████░░░░   3/5   │  │  ← 진행률 바 (primaryContainer)
│   └──────────────────────┘  │
│   3번 더 완료하면 달성해요! 💪  │  ← bodyMedium + primary
│                              │
└──────────────────────────────┘
```

### 6.4. 홈 화면 연동 — 유통기한 경고 + streak 카드

홈 대시보드 카드(`/home`)에 리워드 데이터를 간략 표시:

```
┌──────────────────────────────┐
│ 우리집 냉장고 현황              │
│ ...                          │
│ 🔥 현재 {n}일 연속 요리 중!     │  ← bodyMedium + secondary 색상
│ ⭐ 오늘도 streak 이어가세요!    │  ← bodySmall + onSurfaceVariant
└──────────────────────────────┘
```

### 6.5. 위젯 목록

| 위젯 | 위치 | 역할 |
|------|------|------|
| `StreakCard` | `/my/reward` 상단 | 연속 기록 + 요일 도트 7개 |
| `WeekDotRow` | StreakCard 내부 | 최근 7일 활동 여부 표시 |
| `StatCard` | `/my/reward` 중단 | 통계 숫자 1건 (숫자+라벨) |
| `AchievementGrid` | `/my/reward` 하단 | 업적 3열 그리드 |
| `AchievementTile` | AchievementGrid 셀 | 업적 이모지 + 이름 + 달성/미달성 상태 |
| `AchievementPopup` | 전체 화면 오버레이 | 달성 축하 모달 (Lottie + 이모지 팝) |
| `AchievementDetailSheet` | 바텀시트 | 업적 상세 + 진행률 바 |
| `ProgressBar` | AchievementDetailSheet 내부 | 달성 진행률 (primaryContainer) |
| `StreakMiniCard` | 홈 화면 대시보드 | streak 간략 표시 |
| `NewAchievementSnackBar` | 전역 | 백그라운드 달성 시 간략 알림 |

### 6.6. 상호작용 및 애니메이션

| 이벤트 | 효과 | 타이밍 |
|--------|------|--------|
| 업적 달성 팝업 등장 | 카드 스케일 0→1 (300ms, ElasticOut) + `mediumImpact()` + `recipe_complete.wav` | 달성 직후 |
| 이모지 팝 | 스케일 0.5→1.2→1.0 (500ms, Bounce) | 팝업 등장 후 100ms |
| Confetti Lottie | 전체 오버레이 1회 재생 | 팝업 등장 동시 |
| StreakCard 숫자 | CountUp 애니메이션 (0→N, 600ms, EaseOut) | 화면 진입 후 |
| StatCard 숫자 | CountUp 애니메이션 (0→N, 400ms, EaseOut, 50ms stagger) | 화면 진입 후 |
| AchievementTile 달성 | 그레이스케일 → 컬러 (300ms) + `lightImpact()` | 달성 순간 |
| AchievementGrid 등장 | Fade + SlideUp stagger (60ms 간격) | 화면 진입 후 |
| WeekDotRow | 오늘 dot에 pulse ring (Primary, 1.5초 루프) | 오늘 활동 시 |
| 진행률 바 채우기 | Width 0→N% (500ms, EaseInOut) | 바텀시트 등장 후 |
| Streak 마일스톤 (7·14·30) | 특별 Lottie (불꽃/별/트로피) + `heavyImpact()` | 달성 직후 |

### 6.7. 타이포그래피 매핑

> `design_system.md §1.2.4 (리워드)` 기준.

| 요소 | 스타일 | 예시 |
|------|--------|------|
| AppBar 제목 | `titleLarge` (20sp SemiBold) | "나의 기록" |
| 연속 기록 숫자 | `displaySmall` (26sp Bold) | "7" |
| 연속 기록 라벨 | `bodyMedium` | "일 연속 요리!" |
| 통계 숫자 | `displaySmall` (26sp Bold) | "12" |
| 통계 라벨 | `bodySmall` | "총 요리" |
| 업적 섹션 헤더 | `titleMedium` | "🏆 업적" |
| AchievementTile 이름 | `titleSmall` | "첫 요리사" |
| AchievementTile 조건 | `bodySmall` | "레시피 완료 1회" |
| 달성 팝업 제목 | `headlineSmall` | "업적 달성!" |
| 달성 팝업 이름 | `titleMedium` | "한 달 연속" |
| 달성 팝업 설명 | `bodyMedium` | "30일 연속 요리를 기록했어요." |
| 달성 팝업 날짜 | `bodySmall` + onSurfaceVariant | "달성일: 2026.05.24" |
| 진행률 안내 | `bodyMedium` + primary | "3번 더 완료하면 달성해요! 💪" |

### 6.8. 디자인 톤 가이드

| DO ✅ | DON'T ❌ |
|--------|---------|
| "축하해요! 첫 요리를 완성했어요 🎉" | "미션을 완료하세요" |
| "멋진 기록이에요! 계속 이어가세요" | "매일 요리하지 않으면 streak가 끊겨요" |
| "7일 동안 낭비 없이 요리했어요! 지구도 기뻐해요 🌍" | "재고를 버리지 마세요" |
| "3번 더 완료하면 달성해요! 💪" | "아직 5회 중 3회 남았습니다" |
| 자연스러운 발견의 기쁨 | 강압적 알림, 진행률 압박 |

---

## 7. Acceptance Criteria

| # | 기준 | 검증 방법 | 에이전트 |
|---|------|----------|---------|
| AC-1 | 재고 첫 등록 시 `first_stock` 업적 달성 | Unit Test | Bridge |
| AC-2 | 레시피 완료 1/5/20/50회 누적 시 해당 업적 달성 | Unit Test | Bridge |
| AC-3 | 3·7·14·30일 연속 도달 시 streak 업적 달성 | Unit Test | Bridge |
| AC-4 | 동일 업적 중복 달성 없음 | Unit Test | Bridge |
| AC-5 | 업적 달성 시 팝업 + `mediumImpact()` + 사운드 | UI 확인 | Artisan |
| AC-6 | 리워드 대시보드: StreakCard + 통계 5종 + 업적 그리드 표시 | UI 확인 | Artisan |
| AC-7 | 미달성 업적: 흐린 이모지 + 자물쇠 표시 | UI 확인 | Artisan |
| AC-8 | 업적 탭 → 상세 바텀시트 (조건·달성일·진행률) | UI 확인 | Artisan |
| AC-9 | 통계 숫자 CountUp 애니메이션 (화면 진입 시) | UI 확인 | Artisan |
| AC-10 | 연속 기록 UTC 자정 기준 정확 계산 | Unit Test | Bridge |
| AC-11 | 앱 재시작 후 통계·업적 상태 유지 (Isar 영속화) | 수동 테스트 | Bridge |
| AC-12 | OCR 첫 저장 → `first_ocr`, 음성 첫 저장 → `first_voice` | Unit Test | Bridge |
| AC-13 | `zero_waste`: 유통기한 초과 재료 0개 × 7일 연속 달성 | Unit Test | Bridge |
| AC-14 | 홈 화면 대시보드에 streak 간략 표시 | UI 확인 | Artisan |

---

## 8. Edge Cases

| 상황 | 처리 |
|------|------|
| 앱 삭제 후 재설치 | 로컬 초기화. Phase 2.0+에서 서버 동기화로 복원 |
| 날짜 변경선 (UTC 자정) | `wasActiveYesterday` / `wasActiveToday` UTC 기준 계산 |
| 동일 업적 중복 이벤트 | `isUnlocked == true` 확인 후 스킵 |
| 오프라인 상태 | 전 로직 로컬 처리 (네트워크 불필요) |
| streak 중 여러 이벤트 동시 | `wasActiveToday` 가드로 한 번만 카운트 |
| 레시피 완료 후 취소 | `recipeCompleted` 이벤트는 취소 불가 (완료 표시 확정 시점에만 dispatch) |
| `zero_waste` 중 재고 추가 후 삭제 | 매일 `appOpened` 시 현재 상태만 체크 (이력 불추적) |
| `column_reader` Phase 2.6 이전 | `isLocked: true` 설정 → 대시보드에 흐린 처리 + "곧 오픈" 라벨 |
| 업적 20개 초과 그리드 표시 | 스크롤 가능 그리드 (LazyGrid) |
| Lottie 파일 로드 실패 | 애니메이션 없이 팝업만 표시 (graceful degradation) |

---

## 9. Phase 2.0+ 확장 계획

| 기능 | 설명 |
|------|------|
| 서버 동기화 | 재설치·기기 변경 시 리워드 데이터 복원 |
| 시즌 챌린지 | 계절별 특별 업적 (예: 봄나물 5종 활용, 김장 재료 등록) |
| 소셜 기록 | 친구와 streak 비교 (선택 opt-in) |
| 칼럼 업적 | `column_reader`, `science_fan` Phase 2.6에서 isLocked 해제 |
| Push 알림 | streak 끊길 위험 시 "오늘도 요리해볼까요? 🍳" 부드러운 리마인더 |

---

## 10. 선행 조건 및 의존성

```
Phase 1.0 (재고 관리)
└── StockRepository.add() → stockAdded 이벤트 트리거 지점
    IsarStockRepository → zero_waste 체크 시 재고 조회

Phase 1.1 (AI 레시피)
└── recipeCompleted 이벤트 트리거 지점 (레시피 완료 표시 액션)
    RecipeType enum → uniqueRecipeTypes 통계 업데이트

Phase 1.2 (OCR) — 선택적
└── ocrItemsSaved 이벤트 → first_ocr, multi_input 업적

Phase 1.3 (음성) — 선택적
└── voiceItemsSaved 이벤트 → first_voice, multi_input 업적

Phase 1.4 (본 문서)
├── Architect: Achievement, UserRewardStats, AchievementCondition Freezed
│             RewardEventType enum, RewardEvent Freezed
│             RewardRepository 인터페이스, 5 Providers
├── Bridge:   RewardTriggerService, AchievementChecker, StatsUpdater
│             IsarAchievement, IsarUserRewardStats 컬렉션
└── Artisan:  /my/reward 화면, AchievementPopup, 위젯 10종

Phase 2.6 (칼럼) — isLocked 업적 해제
```

---

## 11. 파일 구조

```
app/lib/
├── models/
│   ├── achievement.dart                # Architect — Freezed
│   ├── achievement_condition.dart      # Architect — Freezed
│   ├── user_reward_stats.dart          # Architect — Freezed
│   ├── reward_event.dart               # Architect — Freezed
│   └── reward_event_type.dart          # Architect — enum
│
├── repositories/
│   ├── reward_repository.dart                  # Architect — interface
│   └── impl/
│       └── isar_reward_repository.dart         # Bridge — Isar impl
│
├── providers/
│   └── reward_providers.dart           # Architect — 5 providers
│
├── services/
│   ├── reward_trigger_service.dart     # Bridge — 이벤트 오케스트레이터
│   └── achievement_checker.dart        # Bridge — 조건 검사
│
├── views/
│   └── reward/
│       └── reward_screen.dart          # Artisan — 대시보드
│
└── widgets/
    └── reward/
        ├── streak_card.dart            # Artisan — 연속 기록 카드
        ├── week_dot_row.dart           # Artisan — 요일 도트 7개
        ├── stat_card.dart              # Artisan — 통계 숫자 카드
        ├── achievement_grid.dart       # Artisan — 업적 그리드
        ├── achievement_tile.dart       # Artisan — 업적 셀
        ├── achievement_popup.dart      # Artisan — 달성 축하 팝업
        ├── achievement_detail_sheet.dart # Artisan — 상세 바텀시트
        ├── progress_bar.dart           # Artisan — 진행률 바
        ├── streak_mini_card.dart       # Artisan — 홈 화면 streak 요약
        └── new_achievement_snack_bar.dart # Artisan — 간략 알림
```
