import 'package:flutter/material.dart';
import 'package:whipup/models/column_category.dart';
import 'package:whipup/theme/app_theme.dart';

/// 칼럼 카테고리 뱃지 (labelSmall, 라운드 4).
class ColumnCategoryBadge extends StatelessWidget {
  const ColumnCategoryBadge({super.key, required this.category});

  final ColumnCategory category;

  /// 카테고리별 (배경, 전경) 색상.
  static (Color, Color) _colors(ColumnCategory category) {
    return switch (category) {
      ColumnCategory.ingredient => (AppTheme.badgeIngredientBg, AppTheme.badgeIngredientFg),
      ColumnCategory.science    => (AppTheme.badgeSoupBg,       AppTheme.badgeSoupFg),
      ColumnCategory.gardening  => (AppTheme.badgeMainBg,       AppTheme.badgeMainFg),
      ColumnCategory.safety     => (AppTheme.badgeSafetyBg,     AppTheme.badgeSafetyFg),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
