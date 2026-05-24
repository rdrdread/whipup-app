# 위클리 칼럼 (Phase 2.6)

> **Phase:** 2.6
> **선행 조건:** Phase 2.0 (백엔드 서버) 완료
> **참조 에이전트:** Architect (모델/Provider), Artisan (UI/UX), Bridge (API 클라이언트/개인화), **Editor** (콘텐츠 기획·작성)
> **상위 문서:** `roadmap.md §9`, `product_map.md §3.3`, `design_system.md §5 (칼럼 타이포그래피)`, `screen_layout.md §3.6`

---

## 1. Feature Summary

검수된 요리 지식 칼럼을 앱 내에서 발행·소비하는 콘텐츠 플랫폼.
식품과학·요리문화·식재료 정보를 **신뢰할 수 있는 1차 출처**에 기반하여
사용자가 '다음 요리에서 행동을 바꿀 수 있는 한 가지 인사이트'를 가져갈 수 있도록 설계한다.

> **핵심 철학:** 칼럼은 지식의 '잔소리'가 아니라 **'요리 전 설레는 읽을거리'**.
> 사용자는 칼럼을 읽으며 다음 장보기와 요리에 대한 기대를 품는다.
> 윕업 톤(따뜻함·즐거움·잔소리 금지)을 철저히 유지한다.

> **Design Creed 연결 (`design_system.md §0`):**
> - *Context-First* — 칼럼은 냉장고 재고와 연결되는 맥락 정보를 제공 (예: 보유 재료 관련 칼럼 우선 노출 예정).
> - *Reward Loop* — 칼럼 완독 시 리워드 시스템과 연동 (`columnRead` 이벤트 → Phase 1.4).
> - *One-Action Rule* — 칼럼 상세에서 "이 재료 추가" CTA로 재고 등록까지 1탭.

**전체 콘텐츠 흐름:**

```
Editor 작성·검수
    │
    ▼
app/assets/columns/columns.json (MVP 시드 번들)
    │
    ├── Bridge: LocalColumnRepository → Isar 캐시 없이 JSON 직독
    │
    ├── Phase 2.6+: backend/columns/ 서버 발행
    │       └── Bridge: RemoteColumnRepository → API 클라이언트 호출
    │
    └── Gemini (개인화 헤드라인·요약 생성만 — 본문 생성 절대 금지)
```

---

## 2. User Stories

### US-1: 칼럼 목록 탐색
> "오늘은 어떤 요리 이야기가 있을까? 홈에서 칼럼 탭을 눌렀다."

- **Given:** 앱 실행, 하단 내비게이션 "칼럼" 탭
- **When:** `/column` 화면 진입
- **Then:** 카테고리 필터 칩 + 칼럼 카드 목록 표시
- **And:** 각 카드에 이모지·제목·부제·예상 읽기 시간·카테고리 뱃지 노출

### US-2: 칼럼 상세 읽기
> "당근의 영양소가 왜 익히면 더 많아지는지 궁금해서 클릭했다."

- **Given:** 사용자가 ColumnCard 탭
- **When:** `/column/:id` 화면 진입
- **Then:** 제목·부제·본문 전문 + 출처 칩 + 태그 표시
- **And:** 완독 시(스크롤 끝 도달) `columnRead` 리워드 이벤트 발행

### US-3: 카테고리 필터
> "요리 과학 칼럼만 모아 보고 싶다."

- **Given:** `/column` 화면, 카테고리 필터 칩 영역
- **When:** "과학" 칩 탭
- **Then:** `science` 카테고리 칼럼만 필터링
- **And:** 선택된 칩은 primary 색상으로 강조

### US-4: 출처 확인
> "이 내용이 정말 맞는지 논문을 확인하고 싶다."

- **Given:** 칼럼 상세 화면 하단 출처 섹션
- **When:** Source Chip 탭
- **Then:** URL이 있는 경우 인앱 브라우저(또는 외부 브라우저) 오픈
- **And:** URL이 없는 경우 토스트 "출처: \${source.citation}" 표시

### US-5: 재료 빠른 추가 (Phase 2.6+ 확장)
> "칼럼에서 제철 재료 이야기를 읽고, 바로 재고에 추가하고 싶다."

- **Given:** 칼럼 상세, 태그에 연결된 재료명
- **When:** "이 재료 추가" FAB 탭
- **Then:** `/stock/add` 화면으로 이동, 재료명 pre-fill

---

## 3. Data Models (Architect)

> `lib/models/` 하위에 Freezed로 생성. `product_map.md §3.3` 정의를 준수.

### 3.1. Source 모델

```dart
// lib/models/source.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'source.freezed.dart';
part 'source.g.dart';

/// 칼럼 출처 정보.
/// Editor가 1차 출처(논문/식약처/USDA)를 기재한다.
@freezed
class Source with _$Source {
  const factory Source({
    /// 인용 텍스트 (예: "K. Miglio et al., 2008")
    required String citation,

    /// 출처 URL (논문 DOI, 공공기관 링크 등). 없으면 null.
    String? url,

    /// 출처 유형: paper | government | book | news
    required SourceType type,
  }) = _Source;

  factory Source.fromJson(Map<String, dynamic> json) => _$SourceFromJson(json);
}

/// 출처 유형 열거형.
enum SourceType {
  /// 학술 논문 (DOI 권장)
  paper,
  /// 정부·공공기관 가이드 (식약처, USDA, WHO 등)
  government,
  /// 전문 서적
  book,
  /// 신뢰 기관 뉴스·매거진
  news,
}
```

### 3.2. ColumnCategory 열거형

```dart
// lib/models/column_category.dart

/// 칼럼 카테고리.
/// product_map.md §3.3의 ColumnCategory enum 정의를 따른다.
enum ColumnCategory {
  /// 식재료 특성·보관·선택법
  ingredient,
  /// 요리 과학·조리 원리
  science,
  /// 음식 문화·역사
  culture,
  /// 식품 안전·위생 (공식 가이드 1차 출처만)
  safety,
  /// 제철 재료·시즌 정보
  seasonal;

  /// 화면 표시용 한글 라벨
  String get label {
    switch (this) {
      case ColumnCategory.ingredient: return '재료';
      case ColumnCategory.science:    return '과학';
      case ColumnCategory.culture:    return '문화';
      case ColumnCategory.safety:     return '안전';
      case ColumnCategory.seasonal:   return '제철';
    }
  }

  /// 카테고리 대표 이모지
  String get emoji {
    switch (this) {
      case ColumnCategory.ingredient: return '🥕';
      case ColumnCategory.science:    return '🔬';
      case ColumnCategory.culture:    return '🍜';
      case ColumnCategory.safety:     return '🛡️';
      case ColumnCategory.seasonal:   return '🌿';
    }
  }
}
```

### 3.3. Column 모델

```dart
// lib/models/column_article.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'column_category.dart';
import 'source.dart';

part 'column_article.freezed.dart';
part 'column_article.g.dart';

/// 위클리 칼럼 아티클 모델.
/// Editor가 작성·검수한 내용을 그대로 역직렬화한다.
/// product_map.md §3.3 스키마를 엄격히 준수.
@freezed
class ColumnArticle with _$ColumnArticle {
  const factory ColumnArticle({
    /// 고유 ID (예: col_001)
    required String id,

    /// 칼럼 제목
    required String title,

    /// 부제
    required String subtitle,

    /// 본문 (플레인 텍스트, 단락 구분은 '\n\n')
    required String body,

    /// 카테고리
    required ColumnCategory category,

    /// 태그 목록
    @Default([]) List<String> tags,

    /// 출처 목록 (1개 이상 필수)
    required List<Source> sources,

    /// 대표 이모지 (Twemoji 렌더링)
    required String thumbnailEmoji,

    /// 발행일
    required DateTime publishedAt,

    /// 예상 읽기 시간 (분)
    @Default(3) int readingTimeMinutes,
  }) = _ColumnArticle;

  factory ColumnArticle.fromJson(Map<String, dynamic> json) =>
      _$ColumnArticleFromJson(json);
}
```

### 3.4. ColumnRepository 인터페이스

```dart
// lib/repositories/column_repository.dart
import '../core/result.dart';
import '../models/column_article.dart';
import '../models/column_category.dart';

/// 칼럼 데이터 접근 추상 인터페이스.
/// - MVP: Local JSON 번들 직독 (Bridge가 LocalColumnRepository 구현)
/// - Phase 2.6+: Remote API (Bridge가 RemoteColumnRepository 구현)
abstract class ColumnRepository {
  /// 전체 칼럼 목록 조회.
  Future<Result<List<ColumnArticle>, ColumnError>> getAll();

  /// 카테고리 필터 적용 목록 조회.
  Future<Result<List<ColumnArticle>, ColumnError>> getByCategory(
    ColumnCategory category,
  );

  /// ID로 단일 칼럼 조회.
  Future<Result<ColumnArticle, ColumnError>> getById(String id);
}

/// 칼럼 관련 에러 유형.
enum ColumnError {
  /// JSON 파싱 실패
  parseError,
  /// 네트워크 오류 (Phase 2.6+)
  networkError,
  /// 칼럼 없음
  notFound,
  /// 알 수 없는 오류
  unknown,
}
```

---

## 4. Provider Architecture (Architect)

> 모든 Provider는 `@riverpod` 어노테이션 사용 (riverpod_generator).

### 4.1. Provider 목록

| Provider | 타입 | 역할 |
|----------|------|------|
| `columnRepositoryProvider` | `AsyncNotifier<ColumnRepository>` | Repository DI 진입점 |
| `columnListProvider` | `FutureProvider<List<ColumnArticle>>` | 전체 칼럼 목록 |
| `columnByCategoryProvider` | `FutureProvider<List<ColumnArticle>>` | 카테고리 필터 목록 |
| `columnDetailProvider` | `FutureProvider<ColumnArticle>` | 칼럼 상세 |
| `columnCategoryFilterProvider` | `NotifierProvider<ColumnCategoryFilterNotifier, ColumnCategory?>` | 필터 선택 상태 |

### 4.2. 구현 예시

```dart
// lib/providers/column_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/column_article.dart';
import '../models/column_category.dart';
import '../repositories/column_repository.dart';
import '../core/result.dart';

part 'column_providers.g.dart';

/// 선택된 카테고리 필터 상태.
/// null이면 "전체" 선택.
@riverpod
class ColumnCategoryFilterNotifier extends _$ColumnCategoryFilterNotifier {
  @override
  ColumnCategory? build() => null;

  void select(ColumnCategory? category) => state = category;
}

/// 필터가 적용된 칼럼 목록.
/// category == null이면 전체 목록 반환.
@riverpod
Future<List<ColumnArticle>> filteredColumnList(
  FilteredColumnListRef ref,
) async {
  final repository = await ref.watch(columnRepositoryProvider.future);
  final category = ref.watch(columnCategoryFilterNotifierProvider);

  final result = category == null
      ? await repository.getAll()
      : await repository.getByCategory(category);

  return result.when(
    ok: (articles) => articles,
    err: (error) => throw ColumnException(error),
  );
}

/// 칼럼 상세 데이터.
@riverpod
Future<ColumnArticle> columnDetail(ColumnDetailRef ref, String id) async {
  final repository = await ref.watch(columnRepositoryProvider.future);
  final result = await repository.getById(id);

  return result.when(
    ok: (article) => article,
    err: (error) => throw ColumnException(error),
  );
}
```

---

## 5. Repository Implementation (Bridge)

### 5.1. LocalColumnRepository (MVP)

```dart
// lib/services/local_column_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../repositories/column_repository.dart';
import '../models/column_article.dart';
import '../models/column_category.dart';
import '../core/result.dart';

/// MVP 구현체: app/assets/columns/columns.json에서 직접 읽는다.
/// Phase 2.6 이전까지 사용. Isar 캐시 없이 앱 번들 JSON을 직독.
class LocalColumnRepository implements ColumnRepository {
  static const _assetPath = 'assets/columns/columns.json';

  List<ColumnArticle>? _cache;

  Future<List<ColumnArticle>> _loadFromBundle() async {
    if (_cache != null) return _cache!;
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final jsonList = json.decode(jsonString) as List<dynamic>;
      _cache = jsonList
          .map((e) => ColumnArticle.fromJson(e as Map<String, dynamic>))
          .toList();
      return _cache!;
    } catch (e) {
      throw ColumnException(ColumnError.parseError);
    }
  }

  @override
  Future<Result<List<ColumnArticle>, ColumnError>> getAll() async {
    try {
      final articles = await _loadFromBundle();
      return Result.ok(articles);
    } on ColumnException catch (e) {
      return Result.err(e.error);
    } catch (_) {
      return Result.err(ColumnError.unknown);
    }
  }

  @override
  Future<Result<List<ColumnArticle>, ColumnError>> getByCategory(
    ColumnCategory category,
  ) async {
    final result = await getAll();
    return result.map(
      (articles) => articles.where((a) => a.category == category).toList(),
    );
  }

  @override
  Future<Result<ColumnArticle, ColumnError>> getById(String id) async {
    final result = await getAll();
    return result.flatMap((articles) {
      final article = articles.firstWhere(
        (a) => a.id == id,
        orElse: () => throw ColumnException(ColumnError.notFound),
      );
      return Result.ok(article);
    });
  }
}
```

### 5.2. Gemini 개인화 서비스 (Bridge)

> ⚠️ **Hybrid Strategy 엄수:**
> - Gemini는 **개인화 헤드라인·요약 생성에만** 활용
> - **칼럼 본문 생성에 절대 사용 금지** — Editor 작성본만 사용
> - 실패 시 원본 title/subtitle를 그대로 표시 (Graceful Fallback)

```dart
// lib/services/column_personalization_service.dart
import '../models/column_article.dart';
import '../models/stock_item.dart';

/// Gemini를 활용한 칼럼 개인화 서비스.
/// 본문은 변경하지 않으며, 헤드라인과 요약 텍스트만 재생성한다.
class ColumnPersonalizationService {
  final GeminiService _gemini;

  const ColumnPersonalizationService(this._gemini);

  /// 사용자의 재고 목록을 참고하여 칼럼 헤드라인을 개인화한다.
  ///
  /// 예: 냉장고에 당근이 있는 경우 → "당신의 냉장고 속 당근, 이렇게 먹으면 더 맛있어요"
  /// 실패 시 원본 [article.title]을 반환 (Graceful Fallback).
  Future<String> personalizeHeadline({
    required ColumnArticle article,
    required List<StockItem> userStock,
  }) async {
    final relevantItems = userStock
        .where((item) => article.tags.contains(item.name))
        .take(3)
        .toList();

    if (relevantItems.isEmpty) return article.title;

    try {
      final prompt = _buildHeadlinePrompt(article, relevantItems);
      final response = await _gemini.generateText(
        prompt: prompt,
        maxTokens: 60,
        temperature: 0.5,
      );
      return response.trim().isNotEmpty ? response.trim() : article.title;
    } catch (_) {
      return article.title; // Graceful Fallback
    }
  }

  /// 칼럼 요약 2-3줄 생성.
  /// 실패 시 원본 [article.subtitle] 반환.
  Future<String> generateSummary({
    required ColumnArticle article,
  }) async {
    try {
      final prompt = _buildSummaryPrompt(article);
      final response = await _gemini.generateText(
        prompt: prompt,
        maxTokens: 100,
        temperature: 0.4,
      );
      return response.trim().isNotEmpty ? response.trim() : article.subtitle;
    } catch (_) {
      return article.subtitle;
    }
  }

  String _buildHeadlinePrompt(
    ColumnArticle article,
    List<StockItem> items,
  ) {
    final itemNames = items.map((i) => i.name).join(', ');
    return '''
당신은 따뜻하고 즐거운 요리 앱(윕업)의 카피라이터입니다.
아래 칼럼의 제목을 독자의 냉장고 재료와 연결하여 개인화된 한 줄 헤드라인으로 바꿔주세요.

[원본 제목] ${article.title}
[독자 보유 재료] $itemNames

규칙:
- 30자 이내
- 잔소리하지 말 것
- 따뜻하고 호기심을 자극할 것
- 순수 텍스트만 출력 (따옴표 없음)
''';
  }

  String _buildSummaryPrompt(ColumnArticle article) {
    return '''
당신은 따뜻하고 즐거운 요리 앱(윕업)의 카피라이터입니다.
아래 칼럼을 2-3문장으로 요약해주세요.

[제목] ${article.title}
[부제] ${article.subtitle}
[본문 앞부분] ${article.body.substring(0, article.body.length.clamp(0, 200))}

규칙:
- 핵심 인사이트 한 가지에 집중
- 잔소리하지 말 것
- 순수 텍스트만 출력
''';
  }
}
```

### 5.3. Phase 2.6+ Remote API 클라이언트

> Phase 2.0 백엔드 완료 후 `RemoteColumnRepository`로 교체.

```dart
// lib/services/remote_column_repository.dart
// Phase 2.6+ 구현 예정
// Dio + Retrofit 기반 API 클라이언트
// Endpoint: GET /api/v1/columns
//           GET /api/v1/columns/{id}
// 캐싱: Cache-Control 헤더 + Isar 로컬 캐시 7일 TTL
```

---

## 6. Seed Content (Editor)

> Editor 에이전트 전용 섹션. 코드(`lib/`) 수정 금지.
> 작성 원칙: 한 칼럼 = 한 가지 핵심 메시지. 모든 주장에 1차 출처 필수.

### 6.1. 시드 칼럼 8편 기획안

| ID | 이모지 | 제목 | 카테고리 | 핵심 메시지 | 예상 시간 |
|----|--------|------|---------|------------|---------|
| col_001 | 🥕 | 당근의 재발견: 왜 기름에 볶을수록 영양가가 올라갈까? | science | 베타카로틴은 지용성 — 기름과 조리 시 흡수율 6.5배 증가 | 3분 |
| col_002 | 🥚 | 달걀은 왜 익으면 하얘질까? | science | 단백질 변성(열에 의한 구조 변화)의 원리 | 3분 |
| col_003 | 🧅 | 양파를 자를 때 눈이 따가운 과학적 이유 | science | 알리이나제-프로페닐술펜산 반응; 냉장 보관으로 자극 감소 | 2분 |
| col_004 | 🌿 | 제철 봄나물 완전 정복 — 냉이·달래·쑥의 황금 보관법 | seasonal | 수확 후 호흡 지속 → 냉장 세워 보관으로 신선도 3배 | 3분 |
| col_005 | 🍗 | 닭고기 핑크빛 = 덜 익은 것? 색보다 온도를 믿어야 하는 이유 | safety | 식약처·USDA 기준: 닭고기 내부 75°C 이상이 안전 기준 | 3분 |
| col_006 | 🫙 | 발효식품의 힘 — 된장·김치·요거트의 공통점 | culture | 젖산균·마이야르 반응·미생물 발효의 문화적·과학적 교차점 | 4분 |
| col_007 | 🧂 | 소금이 단맛을 강화하는 역설의 과학 | science | 소금의 이온이 단맛 수용체를 활성화 — 수박에 소금 치는 이유 | 2분 |
| col_008 | 🫒 | 올리브유 가열하면 독 된다? 발연점의 오해와 진실 | science | 엑스트라버진 발연점 190-215°C — 일반 가정 조리엔 충분히 안전 | 3분 |

### 6.2. JSON 시드 번들 스키마 (`app/assets/columns/columns.json`)

```json
[
  {
    "id": "col_001",
    "title": "당근의 재발견: 왜 기름에 볶을수록 영양가가 올라갈까?",
    "subtitle": "지용성 비타민의 비밀",
    "body": "당근 하면 '눈에 좋은 채소'라는 말이 먼저 떠오른다. 그런데 막상 당근을 날것으로 먹을 때와 기름에 볶을 때, 우리 몸이 흡수하는 영양소의 양은 크게 다르다.\n\n당근에 풍부한 베타카로틴은 몸속에서 비타민 A로 전환되는 '지용성 비타민'이다. 지용성이라는 말은 기름에 녹는다는 뜻. 생당근을 씹어 먹을 때는 세포벽이 단단히 막고 있어 베타카로틴이 쉽게 빠져나오지 못한다.\n\n2008년 이탈리아 연구팀(Miglio et al.)의 실험에서는 당근을 끓이거나 볶으면 세포벽이 부드러워지고, 기름과 함께 조리할 경우 베타카로틴 생체이용률이 최대 6.5배 높아진다는 결과가 나왔다.\n\n결론은 단순하다. 당근은 기름 한 방울과 함께 볶을 때 가장 영양가 있다. 채소볶음에 당근을 먼저 넣고 기름에 살짝 볶는 것, 그것이 과학에 가장 가까운 조리법이다.",
    "category": "science",
    "tags": ["당근", "베타카로틴", "지용성비타민", "볶음"],
    "sources": [
      {
        "citation": "Miglio, C. et al. (2008). Effects of Different Cooking Methods on Nutritional and Physicochemical Characteristics of Selected Vegetables. Journal of Agricultural and Food Chemistry, 56(1), 139–147.",
        "url": "https://doi.org/10.1021/jf072304b",
        "type": "paper"
      }
    ],
    "thumbnailEmoji": "🥕",
    "publishedAt": "2026-05-01T00:00:00Z",
    "readingTimeMinutes": 3
  },
  {
    "id": "col_002",
    "title": "달걀은 왜 익으면 하얘질까?",
    "subtitle": "단백질 변성의 과학",
    "body": "투명하던 달걀흰자가 열을 받으면 새하얀 고체로 바뀐다. 이 변화는 마법이 아니라 '단백질 변성(Protein Denaturation)'이라는 화학 반응의 결과다.\n\n달걀흰자의 90%는 물이고, 나머지 대부분은 알부민을 포함한 단백질로 이루어져 있다. 단백질은 아미노산이 특정 3차원 구조로 접혀 있는 형태인데, 이 구조가 빛을 통과시키기 때문에 날달걀흰자는 투명해 보인다.\n\n열이 가해지면 단백질 분자들이 진동하며 그 구조가 풀리고(변성), 이후 서로 얽히면서 새로운 그물 구조를 형성한다. 이 새로운 구조는 빛을 산란시켜 흰색으로 보이게 만든다. 마치 유리가 깨지면 불투명해지는 것과 비슷한 원리다.\n\n온도가 핵심이다. 달걀흰자는 약 60°C부터 굳기 시작하고, 노른자는 65-70°C에서 변성이 일어난다. 저온 수란(63°C, 60분)이 크리미한 질감을 가지는 이유가 바로 여기에 있다.",
    "category": "science",
    "tags": ["달걀", "단백질변성", "조리과학", "수란"],
    "sources": [
      {
        "citation": "McGee, H. (2004). On Food and Cooking: The Science and Lore of the Kitchen. Scribner. pp. 70–79.",
        "url": null,
        "type": "book"
      }
    ],
    "thumbnailEmoji": "🥚",
    "publishedAt": "2026-05-08T00:00:00Z",
    "readingTimeMinutes": 3
  },
  {
    "id": "col_005",
    "title": "닭고기 핑크빛 = 덜 익은 것? 색보다 온도를 믿어야 하는 이유",
    "subtitle": "식품 안전의 기준은 색깔이 아니라 온도",
    "body": "닭고기를 구웠는데 속이 살짝 분홍빛이면 '덜 익었나?' 하며 불안해진 적 있을 것이다. 하지만 색깔만으로 닭고기의 안전성을 판단하는 것은 잘못된 방법이다.\n\n닭고기의 색깔은 여러 요인에 의해 결정된다. 닭의 나이, 냉동 이력, 산도(pH), 조리 방법에 따라 완전히 익은 닭고기도 분홍빛을 띨 수 있다. 특히 어린 닭은 뼈가 얇고 다공성이어서 골수에서 미오글로빈 색소가 육질로 배어나와 충분히 익어도 분홍색이 남는 경우가 많다.\n\n올바른 기준은 내부 온도다. 한국 식약처와 미국 USDA(농무부)는 공통적으로 닭고기 내부 온도가 75°C(165°F) 이상에 도달하면 살모넬라를 포함한 대부분의 식중독균이 사멸한다고 명시하고 있다.\n\n가장 신뢰할 수 있는 도구는 요리용 온도계다. 닭 가슴살의 가장 두꺼운 부분에 꽂아 75°C 이상을 확인하면 색깔이 분홍빛이어도 안전하게 먹을 수 있다.",
    "category": "safety",
    "tags": ["닭고기", "식품안전", "조리온도", "살모넬라"],
    "sources": [
      {
        "citation": "식품의약품안전처. (2023). 식중독 예방 조리 가이드라인. 식약처 공식 홈페이지.",
        "url": "https://www.mfds.go.kr",
        "type": "government"
      },
      {
        "citation": "USDA Food Safety and Inspection Service. (2023). Safe Minimum Internal Temperature Chart.",
        "url": "https://www.fsis.usda.gov/food-safety/safe-food-handling-and-preparation/food-safety-basics/safe-temperature-chart",
        "type": "government"
      }
    ],
    "thumbnailEmoji": "🍗",
    "publishedAt": "2026-05-29T00:00:00Z",
    "readingTimeMinutes": 3
  }
]
```

> **Note:** 위 3편은 JSON 샘플이다. col_003, col_004, col_006, col_007, col_008은 동일 스키마로 Editor가 출처 검증 후 작성·병합.

### 6.3. Editor 운영 원칙

**콘텐츠 원칙**

| 원칙 | 설명 |
|------|------|
| **한 칼럼 = 한 메시지** | 하나의 핵심 인사이트에 집중. 여러 주제 혼합 금지 |
| **1차 출처 필수** | 학술 논문(DOI), 공공기관(식약처/USDA/WHO) 인용 없이는 작성 보류 |
| **식품 안전 특별 규칙** | 식중독·보관·온도 정보는 공식 가이드(식약처/USDA)만 허용 |
| **윕업 톤 유지** | 따뜻함·즐거움·잔소리 금지. 독자를 '잘못 먹은 당신'이 아니라 '더 잘 먹을 수 있는 당신'으로 대한다 |
| **Gemini 본문 사용 절대 금지** | 개인화 헤드라인·요약 생성에만 Gemini 사용. 본문은 Editor 검수본만 허용 |

**출처 유형별 허용 기준**

| 유형 | 허용 기준 | 예시 |
|------|----------|------|
| 학술 논문 | 동료 심사(peer-reviewed) 저널, DOI 링크 권장 | Journal of Agricultural and Food Chemistry |
| 정부·공공기관 | 식약처, USDA, WHO, 식품안전정보원 공식 발행 자료 | 식약처 식중독 예방 가이드라인 |
| 전문 서적 | 저자·출판사·연도 명시. 요리과학 분야 권위 서적 | On Food and Cooking (Harold McGee) |
| 뉴스·매거진 | 신뢰 기관 (Scientific American, Bon Appétit 등) 제한적 허용 | — |

**파일 경로 및 갱신 절차**

```
app/assets/columns/columns.json   ← MVP 시드 번들 (Editor 단독 쓰기)
backend/columns/                  ← Phase 2.6+ 서버 발행 (Editor + Bridge 협업)
```

1. Editor가 로컬에서 칼럼 작성·출처 검증
2. `app/assets/columns/columns.json`에 JSON 객체 추가
3. Architect와 스키마 변경 여부 협의 (필드 추가 시)
4. PR 생성 → 사용자 최종 검수 → main 병합

---

## 7. UI/UX Implementation (Artisan)

### 7.1. 화면 목록

| 화면 | 라우트 | 파일 |
|------|--------|------|
| 칼럼 목록 | `/column` | `lib/views/column/column_screen.dart` |
| 칼럼 상세 | `/column/:id` | `lib/views/column/column_detail_screen.dart` |

### 7.2. 칼럼 목록 화면 (`/column`)

**와이어프레임 (`screen_layout.md §3.6` 참조)**

```
┌──────────────────────────────┐
│ AppBar: "칼럼"                │  ← titleLarge (20sp SemiBold)
├──────────────────────────────┤
│ ← 수평 스크롤 카테고리 필터 →    │
│ [전체✓] [재료] [과학] [문화] ..│  ← labelLarge, 선택: primary 색상
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ 🥕  당근의 재발견           │ │  ← titleMedium
│ │     지용성 비타민의 비밀      │ │  ← bodySmall, onSurface 60%
│ │     3분            SCIENCE│ │  ← bodySmall + labelSmall 뱃지
│ └──────────────────────────┘ │
│ ┌──────────────────────────┐ │
│ │ 🥚  달걀은 왜 익으면...     │ │
│ │     단백질 변성의 과학       │ │
│ │     3분            SCIENCE│ │
│ └──────────────────────────┘ │
│         (스크롤)              │
├──────────────────────────────┤
│ [홈] [재고] [레시피] [마이]      │
└──────────────────────────────┘
```

**ColumnScreen 구현**

```dart
// lib/views/column/column_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/column_category.dart';
import '../../providers/column_providers.dart';
import '../../widgets/column/column_card.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/empty_state_widget.dart';

/// 칼럼 목록 화면.
/// Design Creed: 카테고리 필터 → 칼럼 목록 스크롤 → 탭으로 상세 진입.
class ColumnScreen extends ConsumerWidget {
  const ColumnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '칼럼',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Column(
        children: [
          const _CategoryFilterBar(),
          const Expanded(child: _ColumnList()),
        ],
      ),
    );
  }
}

/// 카테고리 필터 수평 스크롤 칩 영역.
class _CategoryFilterBar extends ConsumerWidget {
  const _CategoryFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(columnCategoryFilterNotifierProvider);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: '전체',
            isSelected: selected == null,
            onTap: () => ref
                .read(columnCategoryFilterNotifierProvider.notifier)
                .select(null),
          ),
          ...ColumnCategory.values.map(
            (category) => _FilterChip(
              label: category.label,
              isSelected: selected == category,
              onTap: () => ref
                  .read(columnCategoryFilterNotifierProvider.notifier)
                  .select(category),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: colorScheme.primaryContainer,
        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: isSelected ? colorScheme.onPrimaryContainer : null,
        ),
      ),
    );
  }
}

/// 칼럼 목록 (필터 적용).
class _ColumnList extends ConsumerWidget {
  const _ColumnList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncArticles = ref.watch(filteredColumnListProvider);

    return asyncArticles.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorStateWidget(
        message: '칼럼을 불러오지 못했어요',
        onRetry: () => ref.invalidate(filteredColumnListProvider),
      ),
      data: (articles) {
        if (articles.isEmpty) {
          return const EmptyStateWidget(
            emoji: '📭',
            message: '해당 카테고리 칼럼이 없어요',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: articles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              ColumnCard(article: articles[index]),
        );
      },
    );
  }
}
```

### 7.3. 칼럼 상세 화면 (`/column/:id`)

**와이어프레임**

```
┌──────────────────────────────┐
│ ← AppBar: "칼럼"              │  ← 뒤로가기 + titleLarge
├──────────────────────────────┤
│                              │
│   🥕                         │  ← thumbnailEmoji 64sp (중앙)
│                              │
│   당근의 재발견:                │  ← headlineSmall (굵게)
│   왜 기름에 볶을수록             │
│   영양가가 올라갈까?             │
│                              │
│   지용성 비타민의 비밀            │  ← titleSmall + onSurface 60%
│   SCIENCE  · 3분              │  ← labelSmall 뱃지 + bodySmall
├──────────────────────────────┤
│   당근 하면 '눈에 좋은 채소'...   │  ← bodyLarge (본문)
│   (스크롤)                    │
│   ...기름 한 방울과 함께 볶을 때  │
│   가장 영양가 있다.              │
├──────────────────────────────┤
│   # 태그                      │
│   [당근] [베타카로틴] [지용성비타민] │  ← labelSmall 칩
├──────────────────────────────┤
│   📚 출처                     │
│   [K. Miglio et al., 2008]   │  ← Source Chip (탭 → URL 열기)
└──────────────────────────────┘
```

**ColumnDetailScreen 구현**

```dart
// lib/views/column/column_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/column_providers.dart';
import '../../widgets/column/column_body.dart';
import '../../widgets/column/source_chip.dart';
import '../../widgets/common/error_state_widget.dart';

/// 칼럼 상세 화면.
/// 완독(스크롤 끝 도달) 시 columnRead 리워드 이벤트를 발행한다.
class ColumnDetailScreen extends ConsumerStatefulWidget {
  final String columnId;

  const ColumnDetailScreen({super.key, required this.columnId});

  @override
  ConsumerState<ColumnDetailScreen> createState() =>
      _ColumnDetailScreenState();
}

class _ColumnDetailScreenState extends ConsumerState<ColumnDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _readEventFired = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_readEventFired) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.85) {
      _readEventFired = true;
      // TODO Phase 1.4 연동: RewardTriggerService.dispatch(columnRead)
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncArticle =
        ref.watch(columnDetailProvider(widget.columnId));

    return Scaffold(
      appBar: AppBar(
        title: Text('칼럼',
            style: Theme.of(context).textTheme.titleLarge),
      ),
      body: asyncArticle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorStateWidget(message: '칼럼을 불러오지 못했어요'),
        data: (article) => SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이모지 헤더
              Center(
                child: Text(article.thumbnailEmoji,
                    style: const TextStyle(fontSize: 64)),
              ),
              const SizedBox(height: 16),
              // 제목
              Text(
                article.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              // 부제 + 메타
              Text(
                article.subtitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _CategoryBadge(article.category.label),
                  const SizedBox(width: 8),
                  Text(
                    '· ${article.readingTimeMinutes}분',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const Divider(height: 32),
              // 본문
              ColumnBody(body: article.body),
              const SizedBox(height: 24),
              // 태그
              if (article.tags.isNotEmpty) ...[
                Text('태그',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: article.tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            labelStyle:
                                Theme.of(context).textTheme.labelSmall,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],
              // 출처
              Text('📚 출처',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: article.sources
                    .map((source) => SourceChip(source: source))
                    .toList(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
      ),
    );
  }
}
```

### 7.4. 위젯 명세

#### ColumnCard

```dart
// lib/widgets/column/column_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/column_article.dart';

/// 칼럼 목록에서 사용하는 카드 위젯.
/// design_system.md §5 (칼럼 목록) 타이포그래피 준수.
class ColumnCard extends StatelessWidget {
  final ColumnArticle article;

  const ColumnCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),  // 카드 radius 16dp
      ),
      child: InkWell(
        onTap: () => context.push('/column/${article.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 대표 이모지 (28sp)
              Text(
                article.thumbnailEmoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 titleMedium
                    Text(
                      article.title,
                      style: textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 부제 + 읽기 시간 bodySmall
                    Text(
                      '${article.subtitle} · ${article.readingTimeMinutes}분',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // 카테고리 뱃지 labelSmall
                    _CategoryBadge(label: article.category.label),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
      ),
    );
  }
}
```

#### ColumnBody

```dart
// lib/widgets/column/column_body.dart
import 'package:flutter/material.dart';

/// 칼럼 본문 렌더링 위젯.
/// 단락 구분('\n\n')을 처리하여 단락 간 여백을 추가한다.
/// bodyLarge 스타일 적용 (design_system.md §5).
class ColumnBody extends StatelessWidget {
  final String body;

  const ColumnBody({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    final paragraphs = body.split('\n\n');
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((para) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            para.trim(),
            style: textTheme.bodyLarge,
          ),
        );
      }).toList(),
    );
  }
}
```

#### SourceChip

```dart
// lib/widgets/column/source_chip.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/source.dart';

/// 칼럼 출처를 표시하는 칩 위젯.
/// URL이 있으면 탭 시 외부 브라우저로 열린다.
/// design_system.md §5 (칼럼 상세): bodySmall 스타일.
class SourceChip extends StatelessWidget {
  final Source source;

  const SourceChip({super.key, required this.source});

  Future<void> _handleTap(BuildContext context) async {
    if (source.url != null && source.url!.isNotEmpty) {
      final uri = Uri.parse(source.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('출처: ${source.citation}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = source.url != null && source.url!.isNotEmpty;
    final icon = hasUrl ? Icons.open_in_new : Icons.info_outline;

    return ActionChip(
      avatar: Icon(icon, size: 14),
      label: Text(
        source.citation,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      labelStyle: Theme.of(context).textTheme.bodySmall,
      constraints: const BoxConstraints(maxWidth: 280),
      onPressed: () => _handleTap(context),
    );
  }
}
```

### 7.5. 라우터 연동 (`app_router.dart`)

```dart
// lib/router/app_router.dart 에 추가할 라우트 정의
GoRoute(
  path: '/column',
  pageBuilder: (context, state) => const NoTransitionPage(
    child: ColumnScreen(),
  ),
  routes: [
    GoRoute(
      path: ':id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return MaterialPage(child: ColumnDetailScreen(columnId: id));
      },
    ),
  ],
),
```

### 7.6. 마이크로인터랙션 & 접근성

| 인터랙션 | 구현 | 비고 |
|---------|------|------|
| ColumnCard 탭 | `InkWell` + `HapticFeedback.selectionClick()` | 카드 radius와 동일하게 `borderRadius: 16` |
| 카테고리 필터 칩 선택 | `FilterChip.onSelected` + primary 색상 강조 | 선택 상태 즉시 반영 |
| 완독 감지 | `ScrollController` 85% 스크롤 시 이벤트 발행 | Phase 1.4 리워드 연동 |
| 출처 칩 탭 | `url_launcher` → 외부 브라우저 | URL 없을 시 SnackBar fallback |
| 터치 타겟 | 최소 48dp 보장 (ActionChip 제외 시 `constraints` 설정) | WCAG 2.1 AA |

---

## 8. Asset Bundle 구성

```
app/
└── assets/
    └── columns/
        └── columns.json        ← 시드 칼럼 8편 번들 (Editor 단독 관리)
```

`pubspec.yaml`에 등록:

```yaml
flutter:
  assets:
    - assets/columns/columns.json
```

---

## 9. Error States

| 상황 | UI 처리 |
|------|---------|
| JSON 파싱 오류 | `ErrorStateWidget` + "칼럼을 불러오지 못했어요" + 재시도 버튼 |
| 칼럼 없음 (필터 결과 0) | `EmptyStateWidget` + 📭 이모지 + "해당 카테고리 칼럼이 없어요" |
| Gemini 개인화 실패 | 원본 title/subtitle Graceful Fallback (사용자 노출 없음) |
| URL 열기 실패 | SnackBar로 citation 텍스트 표시 |

---

## 10. Test Coverage (Architect)

### 10.1. Unit Test

```dart
// test/repositories/local_column_repository_test.dart
void main() {
  group('LocalColumnRepository', () {
    test('columns.json을 파싱하여 8편 이상 반환', () async { ... });
    test('카테고리 필터: science만 반환', () async { ... });
    test('존재하지 않는 ID → ColumnError.notFound', () async { ... });
    test('Source.url이 null인 경우도 역직렬화 성공', () async { ... });
  });
}
```

### 10.2. Widget Test

```dart
// test/widgets/column_card_test.dart
void main() {
  testWidgets('ColumnCard: 제목·부제·이모지·카테고리 뱃지 렌더링', (tester) async { ... });
  testWidgets('ColumnCard: 탭 시 /column/:id로 이동', (tester) async { ... });
}

// test/widgets/source_chip_test.dart
void main() {
  testWidgets('SourceChip: URL 있을 때 open_in_new 아이콘', (tester) async { ... });
  testWidgets('SourceChip: URL 없을 때 SnackBar로 citation 표시', (tester) async { ... });
}
```

---

## 11. Phase 연동 계획

| Phase | 변경 내용 |
|-------|---------|
| **MVP (Phase 2.6)** | LocalColumnRepository, 시드 8편, 목록·상세 화면 |
| **Phase 2.6+ (서버)** | RemoteColumnRepository, backend/columns/ API, 7일 TTL 캐시 |
| **Phase 1.4 연동** | 완독 이벤트 → `RewardTriggerService.dispatch(columnRead)` |
| **Phase 2.6+ (개인화)** | Gemini 개인화 헤드라인 활성화 (재고 연동 시) |
| **미래 확장** | 칼럼 즐겨찾기, 칼럼 기반 재고 추가 CTA, 푸시 알림 |
