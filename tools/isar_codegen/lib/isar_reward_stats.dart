import 'package:isar/isar.dart';

part 'isar_reward_stats.g.dart';

/// Isar DB 컬렉션 — 사용자 활동 통계 (싱글톤).
///
/// ID = 1로 고정하여 단일 인스턴스만 유지한다.
/// Clean Architecture: Bridge 레이어 전용.
@collection
class IsarRewardStats {
  /// 싱글톤 ID
  static const int singletonId = 1;

  /// 고정 ID (1)
  Id id = singletonId;

  /// 총 레시피 완료 횟수
  int totalRecipesCompleted = 0;

  /// 현재 연속 요리 일수
  int currentStreak = 0;

  /// 역대 최장 연속 일수
  int longestStreak = 0;

  /// 누적 등록 재료 수
  int totalStocksAdded = 0;

  /// 시도한 레시피 타입 목록 (RecipeType.name 문자열)
  List<String> uniqueRecipeTypeValues = [];

  /// 마지막 활동 날짜 (UTC 기준)
  @Index(type: IndexType.value)
  DateTime? lastActivityDate;
}
