import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/column_article.dart';
import 'package:whipup/models/column_category.dart';
import 'package:whipup/providers/column_providers.dart';
import 'package:whipup/widgets/column/column_category_badge.dart';

/// 칼럼 브라우즈 화면 (`/columns`).
///
/// 카테고리별 섹션으로 칼럼 목록을 보여준다.
/// 각 섹션은 가로 스크롤 카드 리스트로 구성된다.
///
/// 레이아웃: `docs/core/screen_layout.md §3.7`
class ColumnBrowseScreen extends ConsumerWidget {
  const ColumnBrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncArticles = ref.watch(filteredColumnListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '콘텐츠',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => context.push('/my/column'),
            child: const Text(
              '목록 보기',
              style: TextStyle(fontFamily: 'Pretendard'),
            ),
          ),
        ],
      ),
      body: asyncArticles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(
          onRetry: () => ref.invalidate(filteredColumnListProvider),
        ),
        data: (articles) {
          if (articles.isEmpty) return const _EmptyState();
          return _CategorySections(articles: articles);
        },
      ),
    );
  }
}

// ─── 카테고리별 섹션 ───────────────────────────────────────────────────────────

class _CategorySections extends StatelessWidget {
  const _CategorySections({required this.articles});

  final List<ColumnArticle> articles;

  @override
  Widget build(BuildContext context) {
    final byCategory = <ColumnCategory, List<ColumnArticle>>{};
    for (final article in articles) {
      byCategory.putIfAbsent(article.category, () => []).add(article);
    }

    // ColumnCategory.values 순서 유지, 내용 있는 카테고리만
    final categories = ColumnCategory.values
        .where((c) => byCategory.containsKey(c))
        .toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryArticles = byCategory[category]!;
        return _CategorySection(
          category: category,
          articles: categoryArticles,
        );
      },
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.articles,
  });

  final ColumnCategory category;
  final List<ColumnArticle> articles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── 섹션 헤더 ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 6),
              Text(
                category.label,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${articles.length}편',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),

        // ─── 가로 스크롤 카드 ────────────────────────────────────────────
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            itemCount: articles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                _BrowseCard(article: articles[index]),
          ),
        ),
      ],
    );
  }
}

// ─── 브라우즈 카드 ─────────────────────────────────────────────────────────────

class _BrowseCard extends StatelessWidget {
  const _BrowseCard({required this.article});

  final ColumnArticle article;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/my/column/${article.id}'),
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이모지 + 뱃지 행
            Row(
              children: [
                Text(
                  article.thumbnailEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 8),
                ColumnCategoryBadge(category: article.category),
              ],
            ),
            const SizedBox(height: 8),

            // 제목
            Text(
              article.title,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // 읽기 시간
            Text(
              '${article.readingTimeMinutes}분 읽기',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 빈 상태 / 에러 ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📭', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text(
            '아직 칼럼이 없어요',
            style: TextStyle(fontFamily: 'Pretendard', fontSize: 15),
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
          const Text(
            '칼럼을 불러오지 못했어요',
            style: TextStyle(fontFamily: 'Pretendard', fontSize: 15),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
