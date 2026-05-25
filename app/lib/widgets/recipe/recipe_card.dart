import 'package:flutter/material.dart';
import 'package:whipup/models/recipe.dart';
import 'recipe_type_badge.dart';

/// 레시피 카드 위젯.
///
/// 레시피 목록과 캐시 화면에서 사용.
/// 선택 모드(체크박스)와 일반 모드를 지원한다.
///
/// 스타일: `docs/core/design_system.md §8.1`
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.isSelected = false,
    this.onSelectionToggle,
    this.showSelectionBox = false,
  });

  final Recipe recipe;
  final VoidCallback? onTap;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;
  final bool showSelectionBox;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: showSelectionBox ? onSelectionToggle : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // 선택 체크박스
            if (showSelectionBox) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outline,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: cs.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
            ],

            // 레시피 이모지 영역
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('🍽️', style: TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 12),

            // 정보 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RecipeTypeBadge(recipeType: recipe.recipeType),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.title,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${recipe.cookingTimeMinutes}분 · ${recipe.difficulty.label} · ${recipe.servings}인분',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // 즐겨찾기 아이콘 (선택 모드가 아닐 때)
            if (!showSelectionBox)
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
