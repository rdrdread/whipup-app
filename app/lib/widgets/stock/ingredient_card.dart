import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/widgets/stock/expiry_badge.dart';

/// 재고 목록의 개별 재료 카드 위젯.
///
/// - 좌측 컬러 보더: 유통기한 상태에 따라 danger(빨강)/warn(앰버)/기본(투명)
/// - 좌측: 카테고리 이모지 + 재료명 + 수량/단위
/// - 우측: 유통기한 뱃지
/// - 스와이프 삭제 (US-3)
///
/// 디자인: `docs/core/design_system.md §6.1` — 데모 rev.4 flat card
class IngredientCard extends StatelessWidget {
  const IngredientCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onUndoDelete,
    this.showTopBorder = false,
  });

  final StockItem item;

  /// 카드 탭 시 호출 (수정 화면으로 이동)
  final VoidCallback onTap;

  /// 스와이프 삭제 확정 시 호출
  final Future<void> Function() onDelete;

  /// 삭제 직후 '되돌리기' Snackbar에서 복원 시 호출
  final Future<void> Function() onUndoDelete;

  /// 상단에 구분선을 표시할지 여부 (그룹 내 첫 번째 아이템은 false).
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final leftColor = _leftBorderColor();

    return Dismissible(
      key: ValueKey('stock_item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: _DismissBackground(),
      confirmDismiss: (_) async {
        await HapticFeedback.heavyImpact();
        return true;
      },
      onDismissed: (_) async {
        await onDelete();
      },
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: leftColor, width: 4),
                top: showTopBorder
                    ? const BorderSide(
                        color: Color(0x0A000000),
                        width: 1,
                      )
                    : BorderSide.none,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // ─── 이모지 ─────────────────────────────────────────────
                SizedBox(
                  width: 40,
                  child: Text(
                    item.category.emoji,
                    style: const TextStyle(fontSize: 28),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),

                // ─── 재료 정보 ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _quantityLabel(),
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          color: Color(0x992C2C2C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ─── 유통기한 뱃지 ──────────────────────────────────────
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

  Color _leftBorderColor() {
    return switch (item.expiryStatus) {
      ExpiryStatus.danger => AppTheme.dangerRed,
      ExpiryStatus.warning => AppTheme.warningAmber,
      ExpiryStatus.fresh => Colors.transparent,
    };
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
      color: const Color(0xFFFFEBEB),
      padding: const EdgeInsets.only(right: 24),
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline_rounded,
            color: AppTheme.dangerRed,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            '삭제',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.dangerRed,
            ),
          ),
        ],
      ),
    );
  }
}
