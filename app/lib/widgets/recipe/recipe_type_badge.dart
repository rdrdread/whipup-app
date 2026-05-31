import 'package:flutter/material.dart';
import 'package:whipup/models/recipe_type.dart';

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
      RecipeType.main    => (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      RecipeType.soup    => (const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      RecipeType.side    => (const Color(0xFFF1F8E9), const Color(0xFF558B2F)),
      RecipeType.dessert => (const Color(0xFFFCE4EC), const Color(0xFFC62828)),
      RecipeType.snack   => (const Color(0xFFFFF8E1), const Color(0xFFF57F17)),
      RecipeType.drink   => (const Color(0xFFE0F7FA), const Color(0xFF00ACC1)),
      RecipeType.sauce   => (const Color(0xFFF3E5F5), const Color(0xFF6A1B9A)),
    };
  }
}
