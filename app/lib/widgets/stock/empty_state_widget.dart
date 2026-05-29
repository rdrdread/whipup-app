import 'package:flutter/material.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';

/// 재고 목록이 비어있을 때 표시되는 빈 상태 위젯. (AC-6)
///
/// 보관 위치에 따라 다른 이모지와 메시지를 표시한다.
/// 디자인: `docs/core/design_system.md §6.5`
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.storageLocation,
    this.hasFilter = false,
    this.onAddTap,
  });

  /// 현재 선택된 보관 위치 탭
  final StorageLocation storageLocation;

  /// 카테고리 필터 적용 중 여부
  final bool hasFilter;

  /// 재료 추가 버튼 탭 콜백
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    final (emoji, title, subtitle) = hasFilter
        ? ('🔍', '해당 카테고리 재료가 없어요', '다른 카테고리를 선택해 보세요')
        : _getContent();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ─── 이모지 ──────────────────────────────────────────────────
            TwemojiIcon(emoji, size: 56),
            const SizedBox(height: 16),

            // ─── 제목 ────────────────────────────────────────────────────
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // ─── 부제목 ──────────────────────────────────────────────────
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // ─── 추가 버튼 ────────────────────────────────────────────────
            if (onAddTap != null && !hasFilter)
              FilledButton.tonal(
                onPressed: onAddTap,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('재료 추가하기'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  (String, String, String) _getContent() {
    return switch (storageLocation) {
      StorageLocation.fridge => (
          '🧊',
          '냉장고가 비어있어요',
          '식재료를 등록해서 유통기한을\n놓치지 마세요!',
        ),
      StorageLocation.freezer => (
          '❄️',
          '냉동고가 비어있어요',
          '냉동 보관 식재료를 등록해 두면\n레시피 추천에 활용돼요.',
        ),
      StorageLocation.pantry => (
          '📦',
          '팬트리가 비어있어요',
          '쌀, 통조림, 건조식품 등\n상온 보관 재료를 등록해 보세요.',
        ),
      StorageLocation.drawer => (
          '🧂',
          '양념 서랍장이 비어있어요',
          '소금, 간장, 오일 등\n양념류를 등록해 보세요.',
        ),
    };
  }
}
