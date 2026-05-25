import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/achievement.dart';
import 'package:whipup/models/user_reward_stats.dart';

/// 리워드 저장소 추상 인터페이스.
///
/// `docs/features/reward_system.md §4`
abstract class RewardRepository {
  /// 전체 업적 목록 (달성 + 미달성).
  Future<Result<List<Achievement>, AppError>> getAllAchievements();

  /// 특정 업적 달성 처리.
  ///
  /// 이미 달성된 업적은 무시한다 ([Achievement.isUnlocked] 체크).
  Future<Result<Achievement, AppError>> unlockAchievement(String achievementId);

  /// 사용자 활동 통계 조회.
  Future<Result<UserRewardStats, AppError>> getStats();

  /// 사용자 활동 통계 저장.
  Future<Result<void, AppError>> saveStats(UserRewardStats stats);

  /// 레시피 완료 이벤트 — 관련 업적을 체크하고 새로 달성된 업적을 반환.
  Future<Result<List<Achievement>, AppError>> onRecipeCompleted(
    String recipeType,
  );

  /// 재고 추가 이벤트 — 관련 업적을 체크하고 새로 달성된 업적을 반환.
  Future<Result<List<Achievement>, AppError>> onStockAdded();

  /// 앱 일별 진입 이벤트 — 연속 기록 업데이트 및 관련 업적 체크.
  Future<Result<List<Achievement>, AppError>> onDailyOpen();
}
