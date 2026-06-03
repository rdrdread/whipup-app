import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/achievement.dart';
import 'package:whipup/models/user_reward_stats.dart';
import 'package:whipup/providers/isar_provider.dart';
import 'package:whipup/repositories/impl/isar_reward_repository.dart';
import 'package:whipup/repositories/reward_repository.dart';
import 'package:whipup/services/points_service.dart';
import 'package:whipup/services/reward_trigger_service.dart';

part 'reward_providers.g.dart';

// ─── Repository Provider ─────────────────────────────────────────────────────

/// [RewardRepository] Provider (keepAlive).
@Riverpod(keepAlive: true)
Future<RewardRepository> rewardRepository(Ref ref) async {
  final isar = await ref.watch(isarDbProvider.future);
  const trigger = RewardTriggerService(
    repository: _LazyRewardRepository(),
  );
  return IsarRewardRepository(isar: isar, triggerService: trigger);
}

// ─── Achievement Provider ─────────────────────────────────────────────────────

/// 전체 업적 목록 (달성 + 미달성).
@riverpod
Future<List<Achievement>> achievements(Ref ref) async {
  final repository = await ref.watch(rewardRepositoryProvider.future);
  final result = await repository.getAllAchievements();
  return result.valueOrNull ?? AchievementDefinitions.all;
}

// ─── Stats Provider ───────────────────────────────────────────────────────────

/// 사용자 활동 통계.
@riverpod
Future<UserRewardStats> rewardStats(Ref ref) async {
  final repository = await ref.watch(rewardRepositoryProvider.future);
  final result = await repository.getStats();
  return result.valueOrNull ?? const UserRewardStats();
}

// ─── Achievement Unlock Notifier ─────────────────────────────────────────────

/// 새로 달성된 업적 알림 Notifier.
///
/// 업적 달성 시 팝업 표시 용도. 확인 후 초기화한다.
@riverpod
class NewlyUnlockedAchievements extends _$NewlyUnlockedAchievements {
  @override
  List<Achievement> build() => [];

  /// 새 업적 목록을 추가한다.
  void add(List<Achievement> achievements) {
    if (achievements.isNotEmpty) {
      state = [...state, ...achievements];
    }
  }

  /// 첫 번째 업적을 꺼내서 반환한다 (팝업 표시 후 호출).
  Achievement? pop() {
    if (state.isEmpty) return null;
    final first = state.first;
    state = state.sublist(1);
    return first;
  }

  /// 전체 초기화.
  void clear() {
    state = [];
  }
}

// ─── 레시피 완료 핸들러 ───────────────────────────────────────────────────────

/// 레시피 완료 이벤트를 처리하고 업적/통계를 업데이트한다.
Future<void> handleRecipeCompleted(
  WidgetRef ref,
  String recipeId,
  String recipeType,
) async {
  final repositoryAsync = ref.read(rewardRepositoryProvider);
  final repository = await repositoryAsync.when(
    data: (r) async => r,
    loading: () async => null,
    error: (e, _) async => null,
  );
  if (repository == null) return;

  // 레시피 완료 포인트 적립
  await PointsService.addRecipePoints();

  // 레시피 완료 처리
  final result = await repository.onRecipeCompleted(recipeType);
  final unlocked = result.valueOrNull ?? [];

  if (unlocked.isNotEmpty) {
    ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlocked);
  }

  // 업적/통계 캐시 무효화
  ref.invalidate(achievementsProvider);
  ref.invalidate(rewardStatsProvider);
}

/// 재고 추가 이벤트를 처리한다.
Future<void> handleStockAdded(WidgetRef ref) async {
  // 재고 추가 포인트 적립
  await PointsService.addStockPoints();

  final repository = await ref
      .read(rewardRepositoryProvider)
      .whenOrNull(data: (r) async => r);
  if (repository == null) return;

  final result = await repository.onStockAdded();
  final unlocked = result.valueOrNull ?? [];

  if (unlocked.isNotEmpty) {
    ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlocked);
  }

  ref.invalidate(rewardStatsProvider);
  ref.invalidate(achievementsProvider);
}

// ─── Lazy Placeholder ────────────────────────────────────────────────────────

/// RewardTriggerService 생성 시 순환 의존성 방지용 임시 구현.
class _LazyRewardRepository implements RewardRepository {
  const _LazyRewardRepository();
  @override
  Future<Result<List<Achievement>, AppError>> getAllAchievements() async =>
      throw UnimplementedError();
  @override
  Future<Result<Achievement, AppError>> unlockAchievement(String id) async =>
      throw UnimplementedError();
  @override
  Future<Result<UserRewardStats, AppError>> getStats() async =>
      throw UnimplementedError();
  @override
  Future<Result<void, AppError>> saveStats(UserRewardStats stats) async =>
      throw UnimplementedError();
  @override
  Future<Result<List<Achievement>, AppError>> onRecipeCompleted(
          String recipeType) async =>
      throw UnimplementedError();
  @override
  Future<Result<List<Achievement>, AppError>> onStockAdded() async =>
      throw UnimplementedError();
  @override
  Future<Result<List<Achievement>, AppError>> onDailyOpen() async =>
      throw UnimplementedError();
}
