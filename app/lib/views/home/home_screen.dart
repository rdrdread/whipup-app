import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/column_article.dart';
import 'package:whipup/models/recipe_type.dart';
import 'package:whipup/providers/column_providers.dart';
import 'package:whipup/providers/recipe_providers.dart';
import 'package:whipup/providers/stock_providers.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/widgets/column/column_category_badge.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';
import 'package:whipup/widgets/recipe/recipe_type_badge.dart';

/// 홈 화면 (대시보드).
///
/// - 대시보드 카드: 전체 재고 현황 + 유통기한 임박
/// - 빠른 레시피 추천: 캐시된 레시피 슬라이더
/// - 콘텐츠(칼럼): 최신 칼럼 슬라이더
///
/// 레이아웃: `docs/core/screen_layout.md §3.1`
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(stockSummaryProvider);
    final recipesAsync = ref.watch(cachedRecipesProvider);
    final columnsAsync = ref.watch(recentColumnsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'WhipUp',
          style: AppTheme.screenTitleStyle,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: '알림',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/my/settings'),
            tooltip: '설정',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // ─── 대시보드 카드 ─────────────────────────────────────────────
          summaryAsync.when(
            data: (summary) => _DashboardCard(summary: summary),
            loading: () => const _DashboardCard(summary: null),
            error: (_, __) => const _DashboardCard(summary: null),
          ),

          const SizedBox(height: 4),

          // ─── 빠른 레시피 추천 ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: GestureDetector(
              onTap: () => context.go('/recipe'),
              child: const Row(
                children: [
                  TwemojiIcon('🍳', size: 18),
                  SizedBox(width: 6),
                  Text(
                    '빠른 레시피 추천',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.iconGrey),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: recipesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _RecipePlaceholderList(onTap: () => context.go('/recipe')),
              data: (recipes) => recipes.isEmpty
                  ? _RecipePlaceholderList(onTap: () => context.go('/recipe'))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      itemCount: recipes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        return _RecipeSlideCard(
                          emoji: _recipeTypeEmoji(recipe.recipeType),
                          badge: recipe.recipeType.label,
                          badgeColor: _recipeTypeBadgeColor(recipe.recipeType),
                          badgeBg: _recipeTypeBadgeBg(recipe.recipeType),
                          title: recipe.title,
                          meta: '${recipe.cookingTimeMinutes}분 · ${recipe.difficulty.label}',
                          onTap: () => context.push('/recipe/${recipe.id}'),
                        );
                      },
                    ),
            ),
          ),

          // ─── 콘텐츠 ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: GestureDetector(
              onTap: () => context.push('/columns'),
              child: const Row(
                children: [
                  TwemojiIcon('📰', size: 18),
                  SizedBox(width: 6),
                  Text(
                    '콘텐츠',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '전체 보기',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      color: AppTheme.iconGrey,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.iconGrey),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 108,
            child: columnsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (columns) => columns.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      itemCount: columns.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => _ContentCard(
                        article: columns[index],
                        onTap: () => context.push('/my/column/${columns[index].id}'),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── 레시피 타입 헬퍼 ──────────────────────────────────────────────────────────

String _recipeTypeEmoji(RecipeType type) => switch (type) {
      RecipeType.main => '🥘',
      RecipeType.side => '🥗',
      RecipeType.soup => '🫕',
      RecipeType.dessert => '🍮',
      RecipeType.snack => '🍿',
      RecipeType.drink => '🥤',
      RecipeType.sauce => '🫙',
    };

Color _recipeTypeBadgeColor(RecipeType type) => RecipeTypeBadge.colorsOf(type).$2;

Color _recipeTypeBadgeBg(RecipeType type) => RecipeTypeBadge.colorsOf(type).$1;

// ─── 대시보드 카드 ─────────────────────────────────────────────────────────────

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({this.summary});

  final StockSummary? summary;

  @override
  Widget build(BuildContext context) {
    final total = summary?.totalCount ?? 0;
    final expiring = summary?.expiringCount ?? 0;
    final isEmpty = summary != null && total == 0;

    return GestureDetector(
      onTap: () =>
          isEmpty ? context.push('/stock/add') : context.go('/stock'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.shadowPrimary,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 제목 + 숫자 ─────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '보유 재료',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '우리집 냉장고 현황',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        '개',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (isEmpty)
              // ─── 빈 상태 CTA ───────────────────────────────────────────
              const Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '아직 등록된 재료가 없어요. 첫 재료를 추가해 보세요!',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: Colors.white),
                ],
              )
            else ...[
              // ─── 위치별 분류 (overflow-safe) ──────────────────────────
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _LocationChip(
                    emoji: '🧊',
                    label: '냉장 ${summary?.fridgeCount ?? 0}',
                  ),
                  _LocationChip(
                    emoji: '❄️',
                    label: '냉동 ${summary?.freezerCount ?? 0}',
                  ),
                  _LocationChip(
                    emoji: '📦',
                    label: '팬트리 ${summary?.pantryCount ?? 0}',
                  ),
                  _LocationChip(
                    emoji: '🧂',
                    label: '서랍 ${summary?.drawerCount ?? 0}',
                  ),
                ],
              ),

              // ─── 유통기한 상태 (항상 표시) ────────────────────────────
              const Divider(color: Colors.white24, height: 22),
              Row(
                children: [
                  Icon(
                    expiring > 0
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: expiring > 0
                        ? Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              children: [
                                const TextSpan(text: '유통기한 임박 '),
                                TextSpan(
                                  text: '$expiring개',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const TextSpan(text: ' · 지금 확인하기'),
                              ],
                            ),
                          )
                        : const Text(
                            '유통기한 임박 재료가 없어요 👍',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: Colors.white70),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TwemojiIcon(emoji, size: 13),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─── 레시피 슬라이더 카드 ───────────────────────────────────────────────────────

/// 레시피가 없을 때 표시하는 플레이스홀더 (레시피 화면 CTA).
class _RecipePlaceholderList extends StatelessWidget {
  const _RecipePlaceholderList({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 240,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Text('🍳', style: TextStyle(fontSize: 32)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'AI 레시피 추천받기',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '재고 재료로 바로 추천받아요',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 12,
                          color: AppTheme.iconGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecipeSlideCard extends StatelessWidget {
  const _RecipeSlideCard({
    required this.emoji,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
    required this.title,
    required this.meta,
    required this.onTap,
  });

  final String emoji;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;
  final String title;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.dividerSubtle,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            TwemojiIcon(emoji, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '🕐 $meta',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: AppTheme.iconSubtle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 콘텐츠 카드 ───────────────────────────────────────────────────────────────

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.article, required this.onTap});

  final ColumnArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.dividerSubtle,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColumnCategoryBadge(category: article.category),
            const SizedBox(height: 6),
            Text(
              article.title,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                article.subtitle,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  color: AppTheme.iconSubtle,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
