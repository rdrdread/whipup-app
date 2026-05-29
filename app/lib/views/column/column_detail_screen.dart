import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whipup/models/column_article.dart';
import 'package:whipup/providers/column_providers.dart';
import 'package:whipup/widgets/column/column_body.dart';
import 'package:whipup/widgets/column/column_category_badge.dart';
import 'package:whipup/widgets/column/source_chip.dart';

/// 칼럼 상세 화면 (`/my/column/:id`).
///
/// 레이아웃: `docs/core/screen_layout.md §3.6`
class ColumnDetailScreen extends ConsumerWidget {
  const ColumnDetailScreen({super.key, required this.columnId});

  final String columnId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncArticle = ref.watch(columnDetailProvider(columnId));

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
      body: asyncArticle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            '칼럼을 불러오지 못했어요',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        data: (article) => _ColumnDetailBody(article: article),
      ),
    );
  }
}

class _ColumnDetailBody extends StatelessWidget {
  const _ColumnDetailBody({required this.article});

  final ColumnArticle article;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              article.thumbnailEmoji,
              style: const TextStyle(fontSize: 64),
            ),
          ),
          const SizedBox(height: 16),
          Text(article.title, style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            article.subtitle,
            style: textTheme.titleSmall?.copyWith(
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ColumnCategoryBadge(category: article.category),
              const SizedBox(width: 8),
              Text(
                '· ${article.readingTimeMinutes}분',
                style: textTheme.bodySmall,
              ),
            ],
          ),
          const Divider(height: 32),
          ColumnBody(body: article.body),
          if (article.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('태그', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in article.tags)
                  Chip(
                    label: Text('#$tag'),
                    labelStyle: textTheme.labelSmall,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
          if (article.sources.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('📚 출처', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final source in article.sources)
                  SourceChip(source: source),
              ],
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
