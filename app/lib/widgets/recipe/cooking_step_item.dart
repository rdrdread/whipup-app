import 'package:flutter/material.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/models/recipe.dart';

/// 조리 단계 아이템 위젯.
///
/// 레시피 상세 화면의 7단계 조리 가이드에서 사용.
/// 단계 번호, 단계 설명, 팁(Call-out Box)을 표시한다.
///
/// 스타일: `docs/core/design_system.md §5.3`, `§8.5`
class CookingStepItem extends StatelessWidget {
  const CookingStepItem({
    super.key,
    required this.step,
    this.isActive = false,
    this.isCooking = false,
  });

  final RecipeStep step;

  /// 현재 진행 중인 단계 여부.
  final bool isActive;

  /// 조리 모드 (더 큰 폰트) 여부.
  final bool isCooking;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? cs.primaryContainer : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
          width: isActive ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 단계 번호 + Phase 라벨 ─────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 단계 번호 (조리 모드에서 더 크게)
              Container(
                width: isCooking ? 52 : 40,
                height: isCooking ? 52 : 40,
                decoration: BoxDecoration(
                  color: isActive ? cs.primary : AppTheme.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${step.stepNumber}',
                    style: isCooking
                        ? tt.displaySmall?.copyWith(
                            color: isActive ? cs.onPrimary : cs.onSurface,
                            fontWeight: FontWeight.w700,
                          )
                        : tt.titleLarge?.copyWith(
                            color: isActive ? cs.onPrimary : cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Phase 라벨
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      step.phase.name,
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.phase.label,
                    style: tt.titleSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // 타이머 표시 (durationSeconds 있을 때)
              if (step.durationSeconds != null) ...[
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(step.durationSeconds!),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // ─── 단계 설명 ────────────────────────────────────────────────
          Text(
            step.description,
            style: isCooking
                ? tt.bodyLarge
                : tt.bodyMedium?.copyWith(height: 1.6),
          ),

          // ─── 팁 (Call-out Box) ────────────────────────────────────────
          if (step.tip != null && step.tip!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: cs.secondary,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    size: 18,
                    color: cs.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.tip!,
                      style: tt.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds초';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    if (remaining == 0) return '$minutes분';
    return '$minutes분 $remaining초';
  }
}
