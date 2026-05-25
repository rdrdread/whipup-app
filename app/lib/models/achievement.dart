import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';
part 'achievement.g.dart';

/// 업적 도메인 모델.
///
/// 업적 정의 목록: `docs/features/reward_system.md §3.1`
/// `unlockedAt`이 null이면 미달성, 설정되어 있으면 달성 완료.
@freezed
abstract class Achievement with _$Achievement {
  const Achievement._();

  const factory Achievement({
    /// 업적 고유 ID (예: 'first_stock')
    required String id,

    /// 업적 이름
    required String title,

    /// 달성 조건 설명
    required String description,

    /// 대표 이모지
    required String emoji,

    /// 달성 시각 (null = 미달성)
    DateTime? unlockedAt,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);

  /// 달성 여부.
  bool get isUnlocked => unlockedAt != null;
}

// ─── AchievementDefinitions ─────────────────────────────────────────────────

/// 앱 내 전체 업적 정의 목록 (정적 데이터).
///
/// 업적 조건: `docs/features/reward_system.md §3.1`
abstract final class AchievementDefinitions {
  static const List<Achievement> all = [
    Achievement(
      id: 'first_stock',
      title: '첫 재료 등록',
      description: '재료를 처음 등록했어요!',
      emoji: '🥬',
    ),
    Achievement(
      id: 'first_recipe',
      title: '첫 요리사',
      description: '첫 번째 레시피를 완료했어요!',
      emoji: '👨‍🍳',
    ),
    Achievement(
      id: 'recipe_5',
      title: '요리 입문자',
      description: '레시피를 5번 완료했어요',
      emoji: '🍳',
    ),
    Achievement(
      id: 'recipe_20',
      title: '요리 매니아',
      description: '레시피를 20번 완료했어요',
      emoji: '🔥',
    ),
    Achievement(
      id: 'streak_3',
      title: '3일 연속',
      description: '3일 연속 요리했어요!',
      emoji: '⭐',
    ),
    Achievement(
      id: 'streak_7',
      title: '일주일 연속',
      description: '7일 연속 요리했어요!',
      emoji: '🌟',
    ),
    Achievement(
      id: 'streak_30',
      title: '한 달 연속',
      description: '30일 연속 요리했어요!',
      emoji: '🏆',
    ),
    Achievement(
      id: 'explorer',
      title: '탐험가',
      description: '5가지 이상 레시피 종류를 시도했어요',
      emoji: '🗺️',
    ),
    Achievement(
      id: 'zero_waste',
      title: '제로 웨이스트',
      description: '7일간 유통기한 초과 재료 없이 유지했어요',
      emoji: '🌱',
    ),
  ];

  /// ID로 업적 정의를 찾는다.
  static Achievement? findById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
