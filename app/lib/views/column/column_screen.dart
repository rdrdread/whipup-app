import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whipup/models/column_category.dart';
import 'package:whipup/providers/column_providers.dart';
import 'package:whipup/widgets/column/column_card.dart';

/// 칼럼 목록 화면 (`/my/column`).
///
/// 카테고리 필터 칩 + 칼럼 카드 목록.
/// 레이아웃: `docs/core/screen_layout.md §3.6`
class ColumnScreen extends ConsumerWidget {
  const ColumnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '칼럼',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: const [
          _CategoryFilterBar(),
          Expanded(child: _ColumnList()),
        ],
      ),
    );
  }
}

class _CategoryFilterBar extends ConsumerWidget {
  const _CategoryFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(columnCategoryFilterProvider);
    final notifier = ref.read(columnCategoryFilterProvider.notifier);

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _FilterChip(
            label: '전체',
            selected: selected == null,
            onTap: () => notifier.select(null),
          ),
          for (final category in ColumnCategory.values)
            _FilterChip(
              label: category.label,
              selected: selected == category,
              onTap: () => notifier.select(category),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? cs.onPrimary : cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
        selectedColor: cs.primary,
      ),
    );
  }
}

class _ColumnList extends ConsumerWidget {
  const _ColumnList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncArticles = ref.watch(filteredColumnListProvider);

    return asyncArticles.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(
        onRetry: () => ref.invalidate(filteredColumnListProvider),
      ),
      data: (articles) {
        if (articles.isEmpty) {
          return const _EmptyState();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: articles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              ColumnCard(article: articles[index]),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📭', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            '해당 카테고리 칼럼이 없어요',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😢', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            '칼럼을 불러오지 못했어요',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
