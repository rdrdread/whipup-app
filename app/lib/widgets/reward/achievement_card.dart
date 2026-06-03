import 'package:flutter/material.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/models/achievement.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';

/// 업적 카드 위젯.
///
/// 달성 여부에 따라 외관을 다르게 표시한다.
/// - 달성: 이모지 + 이름 + 설명 + 달성일 (vivid)
/// - 미달성: 흐린 아이콘 + 잠금 표시 (dimmed)
///
/// 스타일: `docs/features/reward_system.md §5.1`
class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  final Achievement achievement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isUnlocked = achievement.isUnlocked;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isUnlocked ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUnlocked
                ? cs.primaryContainer.withValues(alpha: 0.6)
                : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked
                  ? cs.primary.withValues(alpha: 0.3)
                  : cs.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 이모지 영역
              Stack(
                alignment: Alignment.center,
                children: [
                  TwemojiIcon(achievement.emoji, size: 32),
                  if (!isUnlocked)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.surface.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // 업적 이름
              Text(
                achievement.title,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isUnlocked ? cs.onSurface : cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // 달성 조건 설명
              Text(
                achievement.description,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // 달성 날짜 (달성 시)
              if (isUnlocked && achievement.unlockedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDate(achievement.unlockedAt!),
                  style: tt.bodySmall?.copyWith(
                    color: cs.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
