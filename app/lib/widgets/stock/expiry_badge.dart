import 'package:flutter/material.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/theme/app_theme.dart';

/// 유통기한 상태를 시각적으로 표시하는 뱃지 위젯.
///
/// fresh(초록), warning(노랑), danger(빨강) 세 가지 상태를 색상으로 구분한다.
/// 디자인: `docs/core/design_system.md §6.5`
/// 유통기한 상태 분류: `docs/features/inventory_management.md §4.4`
class ExpiryBadge extends StatelessWidget {
  const ExpiryBadge({
    super.key,
    required this.status,
    required this.dDayLabel,
  });

  /// 유통기한 상태
  final ExpiryStatus status;

  /// D-day 표시 문자열 (예: D-7, D-2, D+1)
  final String dDayLabel;

  @override
  Widget build(BuildContext context) {
    if (dDayLabel.isEmpty) return const SizedBox.shrink();

    final (color, bgColor) = _getColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        dDayLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
      ),
    );
  }

  (Color, Color) _getColors(BuildContext context) {
    return switch (status) {
      ExpiryStatus.fresh => (
          AppTheme.freshGreen,
          AppTheme.freshGreen.withValues(alpha: 0.12),
        ),
      ExpiryStatus.warning => (
          AppTheme.warningAmber,
          AppTheme.warningAmber.withValues(alpha: 0.12),
        ),
      ExpiryStatus.danger => (
          AppTheme.dangerRed,
          AppTheme.dangerRed.withValues(alpha: 0.12),
        ),
    };
  }
}
