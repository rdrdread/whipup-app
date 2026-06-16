import 'package:flutter/material.dart';
import 'package:whipup/models/recipe_type.dart';
import 'package:whipup/theme/app_theme.dart';

/// RecipeType 배지 위젯.
///
/// 각 레시피 타입에 고유 색상을 부여한 소형 레이블 칩.
/// 스타일: `docs/core/design_system.md §8.4`
class RecipeTypeBadge extends StatelessWidget {
  const RecipeTypeBadge({
    super.key,
    required this.recipeType,
  });

  final RecipeType recipeType;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = RecipeTypeBadge.colorsOf(recipeType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        recipeType.label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  /// 레시피 타입별 (배경색, 전경색) 반환. 앱 전역 Single Source of Truth.
  static (Color bg, Color fg) colorsOf(RecipeType type) {
    return switch (type) {
      RecipeType.main    => (AppTheme.badgeMainBg,    AppTheme.badgeMainFg),
      RecipeType.soup    => (AppTheme.badgeSoupBg,    AppTheme.badgeSoupFg),
      RecipeType.side    => (AppTheme.badgeSideBg,    AppTheme.badgeSideFg),
      RecipeType.dessert => (AppTheme.badgeDessertBg, AppTheme.badgeDessertFg),
      RecipeType.snack   => (AppTheme.badgeSnackBg,   AppTheme.badgeSnackFg),
      RecipeType.drink   => (AppTheme.badgeDrinkBg,   AppTheme.badgeDrinkFg),
      RecipeType.sauce   => (AppTheme.badgeSauceBg,   AppTheme.badgeSauceFg),
    };
  }
}
