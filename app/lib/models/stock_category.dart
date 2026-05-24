// ignore_for_file: constant_identifier_names

/// 재고 카테고리 및 보관 위치 관련 Enum 정의.
///
/// 데이터 계약은 `docs/core/product_map.md §3.1` 참조.

// ─── 카테고리 ─────────────────────────────────────────────────────────────────

/// 식재료 카테고리 (10가지).
enum StockCategory {
  vegetable('채소', '🥬'),
  fruit('과일', '🍎'),
  meat('육류', '🥩'),
  seafood('해산물', '🐟'),
  dairy('유제품', '🧀'),
  grain('곡물', '🌾'),
  seasoning('양념/소스', '🧂'),
  beverage('음료', '🥤'),
  frozen('냉동식품', '🧊'),
  other('기타', '🍽️');

  const StockCategory(this.label, this.emoji);

  /// 한글 표시명
  final String label;

  /// 대표 이모지
  final String emoji;
}

// ─── 보관 위치 ───────────────────────────────────────────────────────────────

/// 식재료 보관 위치 (4가지).
enum StorageLocation {
  fridge('냉장고', '🧊', '냉장 보관 식재료'),
  freezer('냉동고', '❄️', '냉동 보관 식재료'),
  pantry('팬트리', '📦', '상온 보관 (쌀, 통조림, 건조식품 등)'),
  drawer('양념 서랍장', '🧂', '양념, 소스, 오일류');

  const StorageLocation(this.label, this.emoji, this.description);

  /// 한글 표시명
  final String label;

  /// 대표 이모지
  final String emoji;

  /// 보관 위치 설명
  final String description;
}

// ─── 정렬 타입 ───────────────────────────────────────────────────────────────

/// 재고 목록 정렬 기준.
enum SortType {
  name('이름순'),
  expiryDate('유통기한순'),
  addedAt('등록일순');

  const SortType(this.label);

  /// 한글 표시명
  final String label;
}

// ─── 유통기한 상태 ────────────────────────────────────────────────────────────

/// 유통기한 상태 분류.
///
/// fresh: 3일 초과 남음 또는 유통기한 없음
/// warning: 3일 이내
/// danger: 유통기한 초과
enum ExpiryStatus {
  fresh,
  warning,
  danger;

  /// 유통기한 날짜로부터 상태를 계산한다.
  static ExpiryStatus fromExpiryDate(DateTime? expiryDate) {
    if (expiryDate == null) return ExpiryStatus.fresh;
    final now = DateTime.now();
    final diff = expiryDate.difference(now).inDays;
    if (diff < 0) return ExpiryStatus.danger;
    if (diff <= 3) return ExpiryStatus.warning;
    return ExpiryStatus.fresh;
  }

  /// D-day 문자열 반환 (예: D-7, D-2, D+1).
  String dDayLabel(DateTime? expiryDate) {
    if (expiryDate == null) return '';
    final now = DateTime.now();
    final diff = expiryDate.difference(
      DateTime(now.year, now.month, now.day),
    ).inDays;
    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${diff.abs()}';
  }
}
