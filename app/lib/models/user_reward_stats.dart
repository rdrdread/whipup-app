import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_reward_stats.freezed.dart';
part 'user_reward_stats.g.dart';

/// 사용자 활동 통계 도메인 모델.
///
/// 통계 정의: `docs/features/reward_system.md §3.2`
@freezed
abstract class UserRewardStats with _$UserRewardStats {
  const UserRewardStats._();

  const factory UserRewardStats({
    /// 총 레시피 완료 횟수
    @Default(0) int totalRecipesCompleted,

    /// 현재 연속 요리 일수
    @Default(0) int currentStreak,

    /// 역대 최장 연속 일수
    @Default(0) int longestStreak,

    /// 시도한 레시피 타입 목록 (RecipeType.name 문자열)
    @Default([]) List<String> uniqueRecipeTypeValues,

    /// 누적 등록 재료 수
    @Default(0) int totalStocksAdded,

    /// 마지막 활동 날짜
    DateTime? lastActivityDate,
  }) = _UserRewardStats;

  factory UserRewardStats.fromJson(Map<String, dynamic> json) =>
      _$UserRewardStatsFromJson(json);

  /// 시도한 레시피 종류 수.
  int get uniqueRecipeTypeCount => uniqueRecipeTypeValues.length;
}
