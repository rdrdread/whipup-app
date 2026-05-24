import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/widgets/stock/expiry_badge.dart';

/// 재고 목록의 개별 재료 카드 위젯.
///
/// - 좌측: 카테고리 이모지 + 재료명 + 수량/단위
/// - 우측: 유통기한 뱃지
/// - 스와이프 삭제: 왼쪽 스와이프 시 삭제 확인 (US-3)
///
/// 디자인: `docs/core/design_system.md §6.1`
class IngredientCard extends StatelessWidget {
  const IngredientCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onUndoDelete,
  });

  final StockItem item;

  /// 카드 탭 시 호출 (수정 화면으로 이동)
  final VoidCallback onTap;

  /// 스와이프 삭제 확정 시 호출
  final Future<void> Function() onDelete;

  /// 삭제 직후 '되돌리기' Snackbar에서 복원 시 호출
  final Future<void> Function() onUndoDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('stock_item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: _DismissBackground(),
      confirmDismiss: (_) async {
        // US-3: 스와이프 시 HapticFeedback.heavyImpact()
        await HapticFeedback.heavyImpact();
        return true;
      },
      onDismissed: (_) async {
        await onDelete();
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // ─── 이모지 아이콘 ────────────────────────────────────────
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      item.category.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ─── 재료 정보 ────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _quantityLabel(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ─── 유통기한 뱃지 ────────────────────────────────────────
                ExpiryBadge(
                  status: item.expiryStatus,
                  dDayLabel: item.dDayLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _quantityLabel() {
    final qty = item.quantity % 1 == 0
        ? item.quantity.toInt().toString()
        : item.quantity.toString();
    return '$qty ${item.unit}';
  }
}

/// Dismissible 배경 위젯 (삭제 시 표시).
class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            '삭제',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
