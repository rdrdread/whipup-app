import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/column_article.dart';
import 'package:whipup/models/recipe_type.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/providers/column_providers.dart';
import 'package:whipup/providers/recipe_providers.dart';
import 'package:whipup/providers/stock_providers.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/widgets/column/column_category_badge.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';
import 'package:whipup/widgets/recipe/recipe_type_badge.dart';

// ─── 빠른 레시피 데이터 ────────────────────────────────────────────────────────

/// 홈 화면 빠른 레시피 추천용 경량 데이터 클래스.
class _QuickRecipe {
  const _QuickRecipe({
    required this.emoji,
    required this.type,
    required this.title,
    required this.description,
    required this.minutes,
    required this.difficulty,
  });

  final String emoji;
  final RecipeType type;
  final String title;
  final String description;
  final int minutes;
  final RecipeDifficulty difficulty;
}

/// 한국인이 즐겨 만드는 대표 요리 25가지 (AI 불필요, 새로고침 시 페이지 순환).
const _kQuickRecipes = <_QuickRecipe>[
  _QuickRecipe(emoji: '🍲', type: RecipeType.soup, title: '된장찌개', description: '집에서 뚝딱, 깊고 구수한 맛', minutes: 20, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🌶️', type: RecipeType.soup, title: '김치찌개', description: '얼큰하고 시원한 국물 한 냄비', minutes: 25, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🍳', type: RecipeType.main, title: '계란볶음밥', description: '냉장고 털어 만드는 볶음밥', minutes: 10, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🥩', type: RecipeType.main, title: '제육볶음', description: '밥 도둑 매콤 돼지볶음', minutes: 20, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🫕', type: RecipeType.soup, title: '순두부찌개', description: '부드럽고 칼칼한 순두부', minutes: 20, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🌿', type: RecipeType.soup, title: '미역국', description: '담백하고 시원한 생일국', minutes: 30, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🍝', type: RecipeType.main, title: '잡채', description: '당면과 채소의 달달한 조화', minutes: 40, difficulty: RecipeDifficulty.medium),
  _QuickRecipe(emoji: '🍗', type: RecipeType.main, title: '닭갈비', description: '춘천식 매콤달콤 닭볶음', minutes: 30, difficulty: RecipeDifficulty.medium),
  _QuickRecipe(emoji: '🍢', type: RecipeType.snack, title: '떡볶이', description: '매콤달콤 길거리 간식', minutes: 20, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🥩', type: RecipeType.main, title: '불고기', description: '달콤한 간장 소고기구이', minutes: 30, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🥔', type: RecipeType.side, title: '감자조림', description: '짭쪼름 달콤 감자반찬', minutes: 25, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🥚', type: RecipeType.side, title: '계란말이', description: '아침 도시락 단골 메뉴', minutes: 15, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🫘', type: RecipeType.side, title: '두부조림', description: '바삭한 두부에 간장양념', minutes: 20, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🥬', type: RecipeType.side, title: '시금치나물', description: '참기름 향 솔솔 무침', minutes: 10, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🍜', type: RecipeType.soup, title: '콩나물국', description: '시원하고 깔끔한 숙취해소', minutes: 15, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🥒', type: RecipeType.side, title: '오이무침', description: '아삭하고 시원한 여름반찬', minutes: 10, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🐟', type: RecipeType.main, title: '참치김치볶음밥', description: '참치캔으로 만드는 간편식', minutes: 15, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🍢', type: RecipeType.side, title: '어묵볶음', description: '달달짭짤 국민 반찬', minutes: 15, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🍛', type: RecipeType.main, title: '카레라이스', description: '채소 듬뿍 집밥 카레', minutes: 35, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🍗', type: RecipeType.soup, title: '닭볶음탕', description: '칼칼하게 끓인 닭도리탕', minutes: 45, difficulty: RecipeDifficulty.medium),
  _QuickRecipe(emoji: '🥘', type: RecipeType.soup, title: '부대찌개', description: '소시지 햄 가득 부대찌개', minutes: 30, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🥚', type: RecipeType.soup, title: '계란국', description: '5분 만에 뚝딱 간단국', minutes: 5, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🍜', type: RecipeType.main, title: '라볶이', description: '라면 떡볶이 합체 별미', minutes: 15, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🥬', type: RecipeType.side, title: '겉절이', description: '갓 버무린 생배추김치', minutes: 10, difficulty: RecipeDifficulty.easy),
  _QuickRecipe(emoji: '🍖', type: RecipeType.main, title: '갈비찜', description: '명절 단골 감칠맛 찜', minutes: 90, difficulty: RecipeDifficulty.hard),
];

// ─── 홈 화면 ──────────────────────────────────────────────────────────────────

/// 홈 화면 (Minimal 대시보드).
///
/// 섹션 순서: 시간대 멘트 → 빠른 레시피 → 나의 요리 → 보유 재료 대시보드 → 콘텐츠
///
/// 레이아웃: `docs/core/screen_layout.md §3.1`
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _recipePage = 0;

  static const _pageSize = 5;
  static int get _totalPages =>
      (_kQuickRecipes.length + _pageSize - 1) ~/ _pageSize;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(stockSummaryProvider);
    final recipesAsync = ref.watch(cachedRecipesProvider);
    final favoritesAsync = ref.watch(favoriteRecipesProvider);
    final columnsAsync = ref.watch(recentColumnsProvider);

    final favoriteCount = favoritesAsync.asData?.value.length ?? 0;
    final cookedCount = recipesAsync.asData?.value.length ?? 0;

    final pageStart = (_recipePage % _totalPages) * _pageSize;
    final pageRecipes =
        _kQuickRecipes.skip(pageStart).take(_pageSize).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.backgroundColor,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('whipup', style: AppTheme.screenTitleStyle),
            SizedBox(width: 6),
            TwemojiIcon('🍳', size: 24),
          ],
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
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ─── 시간대별 감성 멘트 ─────────────────────────────────────────
          const _TimeTagline(),

          // ─── 빠른 레시피 추천 ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const TwemojiIcon('🍳', size: 18),
                const SizedBox(width: 6),
                const Text(
                  '빠른 레시피 추천',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(
                    () => _recipePage = (_recipePage + 1) % _totalPages,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.refresh_rounded,
                        size: 20, color: AppTheme.iconGrey),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              itemCount: pageRecipes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final r = pageRecipes[i];
                return _RecipeSlideCard(
                  emoji: r.emoji,
                  badge: r.type.label,
                  badgeColor: _recipeTypeBadgeColor(r.type),
                  badgeBg: _recipeTypeBadgeBg(r.type),
                  title: r.title,
                  description: r.description,
                  meta: '${r.minutes}분 · ${r.difficulty.label}',
                  onTap: () => context.push(
                    '/recipe/quick',
                    extra: {'name': r.title, 'emoji': r.emoji},
                  ),
                );
              },
            ),
          ),

          // ─── 나의 요리 ─────────────────────────────────────────────────
          _MyRecipesSection(
            cookedCount: cookedCount,
            favoriteCount: favoriteCount,
          ),

          // ─── 보유 재료 대시보드 ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: GestureDetector(
              onTap: () => context.go('/stock'),
              child: Row(
                children: [
                  const TwemojiIcon('📦', size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    '보유 재료',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  const Spacer(),
                  if (summaryAsync.asData?.value != null)
                    Text(
                      '총 ${summaryAsync.asData!.value.totalCount}개',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        color: AppTheme.iconGrey,
                      ),
                    ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppTheme.iconGrey),
                ],
              ),
            ),
          ),
          summaryAsync.when(
            data: (s) => _StockDashboard(
              summary: s,
              onExpiryTap: () {
                ref.read(stockFilterProvider.notifier).setExpiryAscending();
                context.go('/stock');
              },
            ),
            loading: () => const _StockDashboard(summary: null),
            error: (_, __) => const _StockDashboard(summary: null),
          ),

          // ─── 콘텐츠 ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppTheme.iconGrey),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 126,
            child: columnsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (cols) => cols.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      itemCount: cols.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => _ContentCard(
                        article: cols[i],
                        onTap: () => context.push('/my/column/${cols[i].id}'),
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

Color _recipeTypeBadgeColor(RecipeType type) => RecipeTypeBadge.colorsOf(type).$2;
Color _recipeTypeBadgeBg(RecipeType type) => RecipeTypeBadge.colorsOf(type).$1;

// ─── 시간대별 감성 멘트 ────────────────────────────────────────────────────────

/// 현재 시간대에 맞는 감성 멘트. 탭하면 해당 시간대 추천 요리 목록으로 이동.
class _TimeTagline extends StatelessWidget {
  const _TimeTagline();

  static String _periodFromHour(int hour) => switch (hour) {
    >= 5 && < 10 => 'breakfast',
    >= 10 && < 14 => 'lunch',
    >= 14 && < 18 => 'snack',
    >= 18 && < 22 => 'dinner',
    _ => 'lateNight',
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hour = DateTime.now().hour;

    final (emoji, tagline) = switch (hour) {
      >= 5 && < 10 => ('🌅', '좋은 아침이에요! 오늘 하루도 맛있게 시작해요'),
      >= 10 && < 14 => ('☀️', '점심 시간이 가까워요. 뭘 만들어볼까요?'),
      >= 14 && < 18 => ('🌤', '오후도 힘차게! 간식 하나 어때요?'),
      >= 18 && < 22 => ('🌆', '저녁 메뉴 고민 중이세요? 도와드릴게요'),
      _ => ('🌙', '야식이 당기는 밤이에요'),
    };

    return GestureDetector(
      onTap: () => context.push(
        '/recipe/time?period=${_periodFromHour(hour)}',
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                tagline,
                style: tt.bodySmall?.copyWith(
                  color: AppTheme.iconSubtle,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppTheme.iconSubtle),
          ],
        ),
      ),
    );
  }
}

// ─── 나의 요리 섹션 ────────────────────────────────────────────────────────────

/// 했던 요리 횟수와 찜한 레시피 수를 보여주는 나의 요리 섹션.
class _MyRecipesSection extends StatelessWidget {
  const _MyRecipesSection({
    required this.cookedCount,
    required this.favoriteCount,
  });

  final int cookedCount;
  final int favoriteCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TwemojiIcon('📋', size: 18),
              const SizedBox(width: 6),
              const Text(
                '나의 요리',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MyStatCard(
                  emoji: '🍳',
                  label: '했던 요리',
                  count: cookedCount,
                  unit: '회',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MyStatCard(
                  emoji: '📌',
                  label: '찜',
                  count: favoriteCount,
                  unit: '개',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyStatCard extends StatelessWidget {
  const _MyStatCard({
    required this.emoji,
    required this.label,
    required this.count,
    required this.unit,
  });

  final String emoji;
  final String label;
  final int count;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerSubtle),
        boxShadow: const [
          BoxShadow(
              color: AppTheme.dividerSubtle,
              blurRadius: 4,
              offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji $label',
            style: tt.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 3),
              Text(unit,
                  style: tt.labelSmall?.copyWith(color: AppTheme.iconSubtle)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 보유 재료 대시보드 ────────────────────────────────────────────────────────

/// 3단 구조 보유 재료 카드.
///
/// 1단: 컨테이너별 (냉장/냉동/팬트리/서랍)
/// 2단: 재료 카테고리별 (상위 4종)
/// 3단: 유통기한 임박/초과 — HIGH VISIBILITY
class _StockDashboard extends StatelessWidget {
  const _StockDashboard({required this.summary, this.onExpiryTap});

  final StockSummary? summary;
  final VoidCallback? onExpiryTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final s = summary;
    final isEmpty = s != null && s.totalCount == 0;
    final hasUrgent =
        (s?.expiringCount ?? 0) > 0 || (s?.expiredCount ?? 0) > 0;
    final VoidCallback goToStock =
        () => isEmpty ? context.push('/stock/add') : context.go('/stock');

    // 카드 컨테이너 안에서 1~2단(재고 전체)과 3단(유통기한)을
    // 별도 GestureDetector로 분리하여 각자 다른 동작을 수행한다.
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerSubtle),
        boxShadow: const [
          BoxShadow(
              color: AppTheme.dividerSubtle,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1단 + 2단: 탭 → 재고 화면 ──────────────────────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: goToStock,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ContainerStat('🧊', '냉장', s?.fridgeCount),
                      _ContainerStat('❄️', '냉동', s?.freezerCount),
                      _ContainerStat('📦', '팬트리', s?.pantryCount),
                      _ContainerStat('🧂', '서랍', s?.drawerCount),
                    ],
                  ),
                ),
                const Divider(
                    height: 1, thickness: 1, color: AppTheme.dividerSubtle),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
                  child: s == null || s.topCategories.isEmpty
                      ? Text('카테고리 없음',
                          style: tt.labelSmall
                              ?.copyWith(color: AppTheme.iconSubtle))
                      : Wrap(
                          spacing: 10,
                          runSpacing: 5,
                          children: [
                            ...s.topCategories.map(
                                (c) => _CatBadge(c.$1.emoji, c.$1.label, c.$2)),
                            if (s.topCategories.length <
                                StockCategory.values.length)
                              Text(
                                '외 ${StockCategory.values.length - s.topCategories.length}종',
                                style: tt.labelSmall
                                    ?.copyWith(color: AppTheme.iconSubtle),
                              ),
                          ],
                        ),
                ),
                const Divider(
                    height: 1, thickness: 1, color: AppTheme.dividerSubtle),
              ],
            ),
          ),

          // ─── 3단: 유통기한 — 임박 시 별도 탭으로 유통기한순 정렬 ───────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: hasUrgent ? (onExpiryTap ?? goToStock) : goToStock,
            child: _ExpiryRow(summary: s),
          ),
        ],
      ),
    );
  }
}

// ─── 대시보드 보조 위젯 ────────────────────────────────────────────────────────

class _ContainerStat extends StatelessWidget {
  const _ContainerStat(this.emoji, this.label, this.count);
  final String emoji;
  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        TwemojiIcon(emoji, size: 20),
        const SizedBox(height: 2),
        Text(
          count != null ? '$count' : '--',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(label, style: tt.labelSmall?.copyWith(color: AppTheme.iconSubtle)),
      ],
    );
  }
}

class _CatBadge extends StatelessWidget {
  const _CatBadge(this.emoji, this.label, this.count);
  final String emoji;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 3),
        Text('$label $count',
            style: tt.labelSmall?.copyWith(color: AppTheme.textDark)),
      ],
    );
  }
}

/// 유통기한 행 — 임박/초과 시 고시인성 배지, 양호 시 라인 표시.
class _ExpiryRow extends StatelessWidget {
  const _ExpiryRow({required this.summary});
  final StockSummary? summary;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final s = summary;
    final expiring = s?.expiringCount ?? 0;
    final expired = s?.expiredCount ?? 0;
    final hasUrgent = expiring > 0 || expired > 0;

    if (hasUrgent) {
      return Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
        child: Row(
          children: [
            if (expired > 0) ...[
              _UrgentBadge(
                label: '🚨 초과 ${expired}개',
                color: AppTheme.dangerRed,
              ),
              const SizedBox(width: 8),
            ],
            if (expiring > 0)
              _UrgentBadge(
                label: '⚠️ 임박 ${expiring}개',
                color: AppTheme.warningAmber,
              ),
            const Spacer(),
            Text(
              '지금 확인하기 →',
              style: tt.labelSmall?.copyWith(
                color: expired > 0 ? AppTheme.dangerRed : AppTheme.warningAmber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          _ExpiryDot(AppTheme.freshGreen, '신선 ${s?.freshCount ?? '--'}개'),
          const SizedBox(width: 16),
          _ExpiryDot(AppTheme.warningAmber, '임박 ${s?.expiringCount ?? '--'}개'),
          const SizedBox(width: 16),
          _ExpiryDot(AppTheme.dangerRed, '초과 ${s?.expiredCount ?? '--'}개'),
        ],
      ),
    );
  }
}

class _UrgentBadge extends StatelessWidget {
  const _UrgentBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ExpiryDot extends StatelessWidget {
  const _ExpiryDot(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppTheme.textDark)),
      ],
    );
  }
}

// ─── 레시피 슬라이더 카드 ───────────────────────────────────────────────────────

/// 빠른 레시피 카드 (세로 레이아웃, 158px 너비 → 화면에 2개 동시 노출).
class _RecipeSlideCard extends StatelessWidget {
  const _RecipeSlideCard({
    required this.emoji,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
    required this.title,
    required this.description,
    required this.meta,
    required this.onTap,
  });

  final String emoji;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;
  final String title;
  final String description;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 158,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: AppTheme.dividerSubtle,
                blurRadius: 4,
                offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TwemojiIcon(emoji, size: 26),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 11,
                  color: AppTheme.iconSubtle,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '🕐 $meta',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11,
                color: AppTheme.iconSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 콘텐츠 카드 ───────────────────────────────────────────────────────────────

/// 콘텐츠 카드 (읽기 시간 + 카드 크기 내 요약).
class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.article, required this.onTap});

  final ColumnArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 208,
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: AppTheme.dividerSubtle,
                blurRadius: 4,
                offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ColumnCategoryBadge(category: article.category),
                const Spacer(),
                const Icon(Icons.schedule_outlined,
                    size: 11, color: AppTheme.iconSubtle),
                const SizedBox(width: 2),
                Text(
                  '${article.readingTimeMinutes}분',
                  style: tt.labelSmall?.copyWith(color: AppTheme.iconSubtle),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              article.title,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
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
                  fontSize: 11,
                  color: AppTheme.iconSubtle,
                  height: 1.45,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
