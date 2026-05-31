import 'package:flutter/material.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';

/// 카테고리 필터 칩 위젯.
///
/// 재고 목록 상단의 수평 스크롤 카테고리 필터 영역에서 사용한다.
/// 선택된 칩은 Primary 색상으로 하이라이트된다. (US-4)
///
/// 디자인: `docs/core/design_system.md §6.5`
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  /// null이면 "전체" 칩
  final StockCategory? category;

  /// 선택 상태
  final bool isSelected;

  /// 탭 콜백
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = category?.label ?? '전체';
    final emoji = category?.emoji;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 0.5,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              TwemojiIcon(emoji, size: 13),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
