import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/core/extensions/build_context_extensions.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/models/stock_filter.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/providers/stock_providers.dart';
import 'package:whipup/providers/stock_repository_provider.dart';
import 'package:whipup/widgets/stock/category_chip.dart';
import 'package:whipup/widgets/stock/empty_state_widget.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';
import 'package:whipup/widgets/stock/ingredient_card.dart';

/// 재고 목록 화면.
///
/// - 상단: 보관 위치 탭 (냉장고/냉동고/팬트리/서랍장) — US-4의 서브탭
/// - 중간: 카테고리 필터 칩 + 정렬 드롭다운 — US-4, US-5
/// - 하단: IngredientCard 목록 + FAB — US-1, US-3
///
/// 레이아웃: `docs/core/screen_layout.md §3.2`
class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = StorageLocation.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref
            .read(stockFilterProvider.notifier)
            .setStorageLocation(_tabs[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '재고',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppTheme.primaryColor,
            letterSpacing: -0.25,
          ),
        ),
        centerTitle: false,
        actions: [
          // 검색 버튼 (후속 개발중)
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.showComingSoon(),
            tooltip: '검색',
          ),
          // OCR 스캔 버튼 (Phase 1.2)
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: () => context.showComingSoon(),
            tooltip: '영수증 스캔',
          ),
        ],
        // ─── 보관 위치 탭 바 ──────────────────────────────────────────────
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          dividerColor: Colors.transparent,
          tabs: _tabs
              .map(
                (loc) => Tab(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TwemojiIcon(loc.emoji, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          loc.label,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs
            .map((loc) => _StockTabContent(storageLocation: loc))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final currentLoc =
              _tabs[_tabController.index];
          context.push(
            '/stock/add?location=${currentLoc.name}',
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          '재료 추가',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── 탭별 콘텐츠 ──────────────────────────────────────────────────────────────

/// 각 보관 위치 탭의 콘텐츠 (카테고리 필터 + 재고 목록).
class _StockTabContent extends ConsumerWidget {
  const _StockTabContent({required this.storageLocation});
  final StorageLocation storageLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(stockFilterProvider);
    final isCurrentTab = filter.storageLocation == storageLocation;

    final effectiveFilter = StockFilter(
      storageLocation: storageLocation,
      category: isCurrentTab ? filter.category : null,
      sortBy: isCurrentTab ? filter.sortBy : SortType.addedAt,
      sortAscending: isCurrentTab ? filter.sortAscending : false,
    );

    return Column(
      children: [
        // ─── 카테고리 필터 ───────────────────────────────────────────────
        _CategoryFilterBar(
          selectedCategory: isCurrentTab ? filter.category : null,
          onCategoryTap: isCurrentTab
              ? (cat) => ref
                  .read(stockFilterProvider.notifier)
                  .toggleCategory(cat!)
              : (_) {},
          onAllTap: isCurrentTab
              ? () => ref
                  .read(stockFilterProvider.notifier)
                  .clearCategory()
              : () {},
        ),

        // ─── 정렬 바 ─────────────────────────────────────────────────────
        _SortBar(
          currentSort: isCurrentTab ? filter.sortBy : SortType.addedAt,
          ascending: isCurrentTab ? filter.sortAscending : false,
          onSortChanged: isCurrentTab
              ? (sort) => ref
                  .read(stockFilterProvider.notifier)
                  .setSortBy(sort)
              : (_) {},
        ),

        // ─── 재고 목록 ────────────────────────────────────────────────────
        Expanded(
          child: _StockList(
            filter: effectiveFilter,
            storageLocation: storageLocation,
          ),
        ),
      ],
    );
  }
}

// ─── 카테고리 필터 바 ──────────────────────────────────────────────────────────

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selectedCategory,
    required this.onCategoryTap,
    required this.onAllTap,
  });

  final StockCategory? selectedCategory;
  final void Function(StockCategory?) onCategoryTap;
  final VoidCallback onAllTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          // 전체 칩
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: CategoryChip(
              category: null,
              isSelected: selectedCategory == null,
              onTap: onAllTap,
            ),
          ),
          // 카테고리 칩들
          ...StockCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: CategoryChip(
                category: cat,
                isSelected: selectedCategory == cat,
                onTap: () => onCategoryTap(cat),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 정렬 바 ──────────────────────────────────────────────────────────────────

class _SortBar extends StatelessWidget {
  const _SortBar({
    required this.currentSort,
    required this.ascending,
    required this.onSortChanged,
  });

  final SortType currentSort;
  final bool ascending;
  final void Function(SortType) onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: SortType.values
            .expand((sort) => [
                  if (sort != SortType.values.first) ...[
                    const Text(
                      ' · ',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        color: Color(0x992C2C2C),
                      ),
                    ),
                  ],
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSortChanged(sort);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sort.label,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 13,
                            fontWeight: currentSort == sort
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: currentSort == sort
                                ? const Color(0xFFF04E23)
                                : const Color(0x992C2C2C),
                          ),
                        ),
                        if (currentSort == sort) ...[
                          const SizedBox(width: 2),
                          Icon(
                            ascending
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: const Color(0xFFF04E23),
                          ),
                        ],
                      ],
                    ),
                  ),
                ])
            .toList(),
      ),
    );
  }
}

// ─── 재고 목록 ────────────────────────────────────────────────────────────────

class _StockList extends ConsumerWidget {
  const _StockList({
    required this.filter,
    required this.storageLocation,
  });

  final StockFilter filter;
  final StorageLocation storageLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repositoryAsync = ref.watch(stockRepositoryProvider);

    return repositoryAsync.when(
      data: (repository) {
        return StreamBuilder<List<StockItem>>(
          stream: repository.watchAll(filter),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return EmptyStateWidget(
                storageLocation: storageLocation,
                hasFilter: filter.category != null,
              );
            }

            return ListView(
              padding: const EdgeInsets.only(top: 4, bottom: 96),
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFAF3),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return IngredientCard(
                        key: ValueKey('card_${item.id}'),
                        item: item,
                        showTopBorder: i > 0,
                        onTap: () => context.push('/stock/edit/${item.id}'),
                        onDelete: () async {
                          final deletedItem = item;
                          final result = await repository.delete(item.id);
                          if (context.mounted) {
                            result.when(
                              success: (_) {
                                context.showDeletedWithUndo(
                                  itemName: deletedItem.name,
                                  onUndo: () async {
                                    await repository.add(
                                      deletedItem.copyWith(id: 0),
                                    );
                                  },
                                );
                              },
                              failure: (err) {
                                context.showSnackBar(
                                    '삭제 실패: ${err.message}');
                              },
                            );
                          }
                        },
                        onUndoDelete: () async {
                          await repository.add(item.copyWith(id: 0));
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('재고를 불러올 수 없어요\n$err'),
      ),
    );
  }
}
