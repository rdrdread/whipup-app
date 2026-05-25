import 'package:whipup/models/achievement.dart';
import 'package:whipup/models/user_reward_stats.dart';
import 'package:whipup/repositories/reward_repository.dart';

/// 리워드 트리거 서비스.
///
/// 사용자 활동(재고 추가, 레시피 완료, 앱 진입)에 따라
/// 업적 달성을 체크하고 통계를 업데이트한다.
///
/// 트리거 정의: `docs/features/reward_system.md §6`
class RewardTriggerService {
  const RewardTriggerService({required RewardRepository repository})
      : _repository = repository;

  final RewardRepository _repository;

  /// 레시피 완료 이벤트 처리.
  ///
  /// 새로 달성된 업적 목록을 반환한다.
  Future<List<Achievement>> onRecipeCompleted(String recipeType) async {
    final result = await _repository.onRecipeCompleted(recipeType);
    return result.valueOrNull ?? [];
  }

  /// 재고 추가 이벤트 처리.
  Future<List<Achievement>> onStockAdded() async {
    final result = await _repository.onStockAdded();
    return result.valueOrNull ?? [];
  }

  /// 앱 일별 진입 이벤트 처리.
  Future<List<Achievement>> onDailyOpen() async {
    final result = await _repository.onDailyOpen();
    return result.valueOrNull ?? [];
  }

  /// 연속 기록 계산.
  ///
  /// `docs/features/reward_system.md §6.2` 참조.
  UserRewardStats calculateStreak(UserRewardStats stats) {
    final today = DateTime.now().toUtc();
    final todayDate = DateTime.utc(today.year, today.month, today.day);
    final lastActivity = stats.lastActivityDate;

    if (lastActivity == null) {
      // 최초 활동
      return stats.copyWith(
        currentStreak: 1,
        longestStreak: stats.longestStreak.clamp(1, 9999),
        lastActivityDate: todayDate,
      );
    }

    final lastDate = DateTime.utc(
      lastActivity.year,
      lastActivity.month,
      lastActivity.day,
    );
    final diff = todayDate.difference(lastDate).inDays;

    if (diff == 0) {
      // 오늘 이미 활동함 — 변경 없음
      return stats;
    } else if (diff == 1) {
      // 어제 활동 → 연속 기록 증가
      final newStreak = stats.currentStreak + 1;
      return stats.copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > stats.longestStreak
            ? newStreak
            : stats.longestStreak,
        lastActivityDate: todayDate,
      );
    } else {
      // 이틀 이상 공백 → 연속 기록 리셋 (오늘 활동으로 1)
      return stats.copyWith(
        currentStreak: 1,
        lastActivityDate: todayDate,
      );
    }
  }
}
