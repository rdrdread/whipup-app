import 'package:isar/isar.dart';
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/achievement.dart';
import 'package:whipup/models/recipe_type.dart';
import 'package:whipup/models/user_reward_stats.dart';
import 'package:whipup/repositories/reward_repository.dart';
import 'package:whipup/services/reward_trigger_service.dart';
import 'isar_achievement.dart';
import 'isar_reward_stats.dart';

/// [RewardRepository] Isar 구현체.
///
/// 업적 달성 상태와 활동 통계를 Isar에 영속화한다.
class IsarRewardRepository implements RewardRepository {
  // ignore: prefer_initializing_formals
  IsarRewardRepository({
    required Isar isar,
    required RewardTriggerService triggerService,
  })  : _isar = isar,
        _trigger = triggerService;

  final Isar _isar;
  final RewardTriggerService _trigger;

  @override
  Future<Result<List<Achievement>, AppError>> getAllAchievements() async {
    try {
      final isarItems = await _isar.isarAchievements.where().findAll();
      final unlockedMap = {
        for (final item in isarItems) item.achievementId: item.unlockedAt,
      };

      final achievements = AchievementDefinitions.all.map((def) {
        return def.copyWith(unlockedAt: unlockedMap[def.id]);
      }).toList();

      return Result.success(achievements);
    } catch (e) {
      return Result.failure(AppError.database('업적 조회 실패: $e'));
    }
  }

  @override
  Future<Result<Achievement, AppError>> unlockAchievement(
    String achievementId,
  ) async {
    try {
      final def = AchievementDefinitions.findById(achievementId);
      if (def == null) {
        return Result.failure(
          AppError.database('업적을 찾을 수 없습니다: $achievementId'),
        );
      }

      // 이미 달성된 업적이면 무시
      final existing = await _isar.isarAchievements
          .where()
          .achievementIdEqualTo(achievementId)
          .findFirst();
      if (existing?.unlockedAt != null) {
        return Result.success(def.copyWith(unlockedAt: existing!.unlockedAt));
      }

      final now = DateTime.now().toUtc();
      await _isar.writeTxn(() async {
        final item = IsarAchievement()
          ..id = existing?.id ?? Isar.autoIncrement
          ..achievementId = achievementId
          ..unlockedAt = now;
        await _isar.isarAchievements.put(item);
      });

      return Result.success(def.copyWith(unlockedAt: now));
    } catch (e) {
      return Result.failure(AppError.database('업적 달성 저장 실패: $e'));
    }
  }

  @override
  Future<Result<UserRewardStats, AppError>> getStats() async {
    try {
      final item = await _isar.isarRewardStats.get(IsarRewardStats.singletonId);
      if (item == null) {
        return const Result.success(UserRewardStats());
      }
      return Result.success(_toDomain(item));
    } catch (e) {
      return Result.failure(AppError.database('통계 조회 실패: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> saveStats(UserRewardStats stats) async {
    try {
      await _isar.writeTxn(() async {
        final item = _toIsar(stats);
        await _isar.isarRewardStats.put(item);
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppError.database('통계 저장 실패: $e'));
    }
  }

  @override
  Future<Result<List<Achievement>, AppError>> onRecipeCompleted(
    String recipeType,
  ) async {
    try {
      final statsResult = await getStats();
      if (statsResult.isFailure) return Result.failure(statsResult.errorOrNull!);
      var stats = statsResult.valueOrNull!;

      // 통계 업데이트
      stats = stats.copyWith(
        totalRecipesCompleted: stats.totalRecipesCompleted + 1,
        uniqueRecipeTypeValues: _addUniqueType(
          stats.uniqueRecipeTypeValues,
          recipeType,
        ),
      );
      // 연속 기록 업데이트
      stats = _trigger.calculateStreak(stats);
      await saveStats(stats);

      // 업적 체크
      final newlyUnlocked = <Achievement>[];
      final completed = stats.totalRecipesCompleted;

      if (completed == 1) newlyUnlocked.addAll(await _tryUnlock('first_recipe'));
      if (completed == 5) newlyUnlocked.addAll(await _tryUnlock('recipe_5'));
      if (completed == 20) newlyUnlocked.addAll(await _tryUnlock('recipe_20'));

      // 탐험가 업적 (5종류 이상)
      if (stats.uniqueRecipeTypeValues.length >= RecipeType.values.length - 2) {
        newlyUnlocked.addAll(await _tryUnlock('explorer'));
      }

      // 연속 기록 업적
      if (stats.currentStreak >= 3) newlyUnlocked.addAll(await _tryUnlock('streak_3'));
      if (stats.currentStreak >= 7) newlyUnlocked.addAll(await _tryUnlock('streak_7'));
      if (stats.currentStreak >= 30) newlyUnlocked.addAll(await _tryUnlock('streak_30'));

      return Result.success(newlyUnlocked);
    } catch (e) {
      return Result.failure(AppError.unknown(e));
    }
  }

  @override
  Future<Result<List<Achievement>, AppError>> onStockAdded() async {
    try {
      final statsResult = await getStats();
      if (statsResult.isFailure) return Result.failure(statsResult.errorOrNull!);
      var stats = statsResult.valueOrNull!;

      stats = stats.copyWith(totalStocksAdded: stats.totalStocksAdded + 1);
      await saveStats(stats);

      final newlyUnlocked = <Achievement>[];
      if (stats.totalStocksAdded == 1) {
        newlyUnlocked.addAll(await _tryUnlock('first_stock'));
      }

      return Result.success(newlyUnlocked);
    } catch (e) {
      return Result.failure(AppError.unknown(e));
    }
  }

  @override
  Future<Result<List<Achievement>, AppError>> onDailyOpen() async {
    try {
      final statsResult = await getStats();
      if (statsResult.isFailure) return Result.failure(statsResult.errorOrNull!);
      final stats = _trigger.calculateStreak(statsResult.valueOrNull!);
      await saveStats(stats);

      final newlyUnlocked = <Achievement>[];
      if (stats.currentStreak >= 3) newlyUnlocked.addAll(await _tryUnlock('streak_3'));
      if (stats.currentStreak >= 7) newlyUnlocked.addAll(await _tryUnlock('streak_7'));
      if (stats.currentStreak >= 30) newlyUnlocked.addAll(await _tryUnlock('streak_30'));

      return Result.success(newlyUnlocked);
    } catch (e) {
      return Result.failure(AppError.unknown(e));
    }
  }

  // ─── 내부 헬퍼 ─────────────────────────────────────────────────────────────

  /// 특정 업적을 달성 처리하고, 신규 달성 시 해당 업적을 반환한다.
  Future<List<Achievement>> _tryUnlock(String achievementId) async {
    final existing = await _isar.isarAchievements
        .where()
        .achievementIdEqualTo(achievementId)
        .findFirst();
    if (existing?.unlockedAt != null) return []; // 이미 달성

    final result = await unlockAchievement(achievementId);
    return result.isSuccess ? [result.valueOrNull!] : [];
  }

  List<String> _addUniqueType(List<String> current, String type) {
    if (current.contains(type)) return current;
    return [...current, type];
  }

  UserRewardStats _toDomain(IsarRewardStats item) => UserRewardStats(
        totalRecipesCompleted: item.totalRecipesCompleted,
        currentStreak: item.currentStreak,
        longestStreak: item.longestStreak,
        totalStocksAdded: item.totalStocksAdded,
        uniqueRecipeTypeValues: List.from(item.uniqueRecipeTypeValues),
        lastActivityDate: item.lastActivityDate,
      );

  IsarRewardStats _toIsar(UserRewardStats stats) {
    return IsarRewardStats()
      ..id = IsarRewardStats.singletonId
      ..totalRecipesCompleted = stats.totalRecipesCompleted
      ..currentStreak = stats.currentStreak
      ..longestStreak = stats.longestStreak
      ..totalStocksAdded = stats.totalStocksAdded
      ..uniqueRecipeTypeValues = stats.uniqueRecipeTypeValues
      ..lastActivityDate = stats.lastActivityDate;
  }
}
