import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 포인트 시스템 서비스.
///
/// FlutterSecureStorage에 포인트와 활동 수를 저장한다.
/// Provider 불필요 — 화면에서 직접 static 메서드 호출.
///
/// 적립 이벤트: 레시피 완료 +50P, 재고 추가 +10P, 앱 일별 오픈 +5P, 후기 작성 +50P
abstract final class PointsService {
  static const _storage = FlutterSecureStorage();
  static const _pointsKey = 'user_points';
  static const _reviewCountKey = 'user_review_count';
  static const _lastDailyOpenKey = 'user_last_daily_open';

  /// 레시피 완료 적립 포인트.
  static const int pointsPerRecipe = 50;

  /// 재고 추가 적립 포인트.
  static const int pointsPerStock = 10;

  /// 일별 앱 오픈 적립 포인트.
  static const int pointsPerDailyOpen = 5;

  /// 후기 1건당 기본 포인트.
  static const int pointsPerReview = 50;

  /// 첫 후기 보너스.
  static const int firstReviewBonus = 100;

  /// 리워드 구간 (포인트 오름차순).
  static const List<({int points, String emoji, String title, String desc})>
      rewardTiers = [
    (
      points: 100,
      emoji: '🏅',
      title: '윕업 팬 뱃지',
      desc: '요리를 시작한 당신, 진짜 윕업러!'
    ),
    (
      points: 300,
      emoji: '🍳',
      title: '홈쿡 입문',
      desc: '꾸준한 요리로 실력이 쑥쑥 늘고 있어요'
    ),
    (
      points: 500,
      emoji: '📖',
      title: '프리미엄 레시피 구독',
      desc: '셰프 큐레이션 레시피 30일 무료 이용'
    ),
    (
      points: 1000,
      emoji: '⭐',
      title: '마스터쿡 뱃지',
      desc: '냉장고를 정복한 요리 고수!'
    ),
    (
      points: 2000,
      emoji: '🎁',
      title: '신선 재료 박스',
      desc: '제철 재료 박스를 집 앞까지 배달해 드려요'
    ),
    (
      points: 3000,
      emoji: '🏆',
      title: '윕업 챔피언',
      desc: '최고의 키친 컴패니언, 당신이 바로 챔피언!'
    ),
  ];

  static Future<int> getPoints() async {
    final raw = await _storage.read(key: _pointsKey);
    return int.tryParse(raw ?? '0') ?? 0;
  }

  static Future<int> getReviewCount() async {
    final raw = await _storage.read(key: _reviewCountKey);
    return int.tryParse(raw ?? '0') ?? 0;
  }

  /// 레시피 완료 시 포인트 적립 (+50P).
  static Future<int> addRecipePoints() async {
    final current = await getPoints();
    final next = current + pointsPerRecipe;
    await _storage.write(key: _pointsKey, value: next.toString());
    return next;
  }

  /// 재고 추가 시 포인트 적립 (+10P).
  static Future<int> addStockPoints() async {
    final current = await getPoints();
    final next = current + pointsPerStock;
    await _storage.write(key: _pointsKey, value: next.toString());
    return next;
  }

  /// 일별 앱 오픈 시 포인트 적립 (+5P, 하루 1회).
  ///
  /// 오늘 이미 적립했으면 0 반환.
  static Future<int> addDailyOpenPoints() async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final last = await _storage.read(key: _lastDailyOpenKey);
    if (last == todayStr) return 0;
    await _storage.write(key: _lastDailyOpenKey, value: todayStr);
    final current = await getPoints();
    final next = current + pointsPerDailyOpen;
    await _storage.write(key: _pointsKey, value: next.toString());
    return next;
  }

  /// 후기 작성 시 포인트 적립.
  ///
  /// 반환: `(totalPoints: 누적 포인트, earned: 이번에 적립된 포인트)`
  static Future<({int totalPoints, int earned})> addReviewPoints() async {
    final count = await getReviewCount();
    final current = await getPoints();
    final isFirst = count == 0;
    final earned = pointsPerReview + (isFirst ? firstReviewBonus : 0);
    final next = current + earned;
    await Future.wait([
      _storage.write(key: _pointsKey, value: next.toString()),
      _storage.write(key: _reviewCountKey, value: (count + 1).toString()),
    ]);
    return (totalPoints: next, earned: earned);
  }

  /// 최고 달성 리워드 구간 인덱스 (-1: 없음).
  static int reachedTierIndex(int points) {
    for (int i = rewardTiers.length - 1; i >= 0; i--) {
      if (points >= rewardTiers[i].points) return i;
    }
    return -1;
  }

  /// 다음 목표 리워드 구간 (null: 모두 달성).
  static ({int points, String emoji, String title, String desc})?
      nextTier(int points) {
    for (final tier in rewardTiers) {
      if (points < tier.points) return tier;
    }
    return null;
  }
}
