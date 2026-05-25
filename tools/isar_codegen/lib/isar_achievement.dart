import 'package:isar/isar.dart';

part 'isar_achievement.g.dart';

/// Isar DB 컬렉션 — 업적 달성 상태.
///
/// AchievementDefinitions 정적 목록과 연동하여
/// 각 업적의 달성 여부와 달성 시각을 영속화한다.
///
/// Clean Architecture: Bridge 레이어 전용.
@collection
class IsarAchievement {
  /// Isar 자동 증가 ID
  Id id = Isar.autoIncrement;

  /// 업적 고유 ID (예: 'first_stock')
  @Index(type: IndexType.value, unique: true)
  late String achievementId;

  /// 달성 시각 (null = 미달성)
  @Index(type: IndexType.value)
  DateTime? unlockedAt;
}
