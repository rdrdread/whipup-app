import 'package:flutter/material.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/models/stock_item.dart';

/// 레시피 재료 체크리스트 위젯.
///
/// 레시피에 필요한 재료와 사용자 보유 재료를 대조하여
/// 보유 여부를 시각적으로 표시한다.
///
/// 스타일: `docs/core/screen_layout.md §3.5`
class IngredientCheckList extends StatelessWidget {
  const IngredientCheckList({
    super.key,
    required this.ingredients,
    this.ownedItems = const [],
  });

  final List<RecipeIngredient> ingredients;

  /// 사용자 보유 재료 목록 (보유 여부 판단에 사용).
  final List<StockItem> ownedItems;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: ingredients.map((ingredient) {
        final isOwned = _isOwned(ingredient.name);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // 보유 여부 아이콘
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isOwned
                      ? cs.primaryContainer
                      : AppTheme.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOwned
                      ? Icons.check_rounded
                      : Icons.add_rounded,
                  size: 14,
                  color: isOwned ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),

              // 재료명 + 수량
              Expanded(
                child: Text(
                  ingredient.name,
                  style: tt.bodyMedium?.copyWith(
                    color: isOwned
                        ? cs.onSurface
                        : cs.onSurface.withValues(alpha: 0.6),
                    decoration: isOwned ? null : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // 수량
              Text(
                '${ingredient.amount}${ingredient.unit}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // 선택 재료 표시
              if (ingredient.isOptional) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '선택',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _isOwned(String ingredientName) {
    final nameLower = ingredientName.toLowerCase();
    return ownedItems.any(
      (item) => item.name.toLowerCase().contains(nameLower) ||
          nameLower.contains(item.name.toLowerCase()),
    );
  }
}
