import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/column_article.dart';
import 'package:whipup/widgets/column/column_category_badge.dart';

/// 칼럼 목록 카드.
///
/// 타이포그래피: `docs/core/design_system.md §5 (칼럼 목록)`
class ColumnCard extends StatelessWidget {
  const ColumnCard({super.key, required this.article});

  final ColumnArticle article;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/my/column/${article.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.thumbnailEmoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${article.subtitle} · ${article.readingTimeMinutes}분',
                      style: textTheme.bodySmall?.copyWith(
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ColumnCategoryBadge(category: article.category),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
