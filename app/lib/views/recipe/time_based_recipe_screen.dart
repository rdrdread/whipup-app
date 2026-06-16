import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/models/recipe_type.dart';
import 'package:whipup/providers/recipe_providers.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';
import 'package:whipup/widgets/recipe/recipe_type_badge.dart';

// ─── 경량 레시피 엔트리 ────────────────────────────────────────────────────────

class _RecipeEntry {
  const _RecipeEntry(
    this.emoji,
    this.title,
    this.description,
    this.minutes,
    this.difficulty,
    this.type,
  );

  final String emoji;
  final String title;
  final String description;
  final int minutes;
  final RecipeDifficulty difficulty;
  final RecipeType type;
}

// ─── 시간대별 레시피 데이터 ────────────────────────────────────────────────────

const _periodRecipes = <String, List<_RecipeEntry>>{
  'breakfast': [
    _RecipeEntry('🥚', '계란말이',    '아침 도시락 단골 메뉴',             15, RecipeDifficulty.easy,   RecipeType.side),
    _RecipeEntry('🌿', '미역국',      '담백하고 시원한 생일국',             30, RecipeDifficulty.easy,   RecipeType.soup),
    _RecipeEntry('🍜', '콩나물국',    '시원하고 깔끔한 아침국',             15, RecipeDifficulty.easy,   RecipeType.soup),
    _RecipeEntry('🥬', '시금치나물',  '참기름 향 솔솔 무침',                10, RecipeDifficulty.easy,   RecipeType.side),
    _RecipeEntry('🍳', '계란볶음밥',  '냉장고 털어 만드는 볶음밥',          10, RecipeDifficulty.easy,   RecipeType.main),
    _RecipeEntry('🥚', '계란국',      '5분 만에 뚝딱 간단국',               5,  RecipeDifficulty.easy,   RecipeType.soup),
    _RecipeEntry('🫘', '두부조림',    '바삭한 두부에 간장양념',             20, RecipeDifficulty.easy,   RecipeType.side),
    _RecipeEntry('🥔', '감자조림',    '달콤짭짤한 밥도둑 반찬',             20, RecipeDifficulty.easy,   RecipeType.side),
    _RecipeEntry('🌶️', '김치볶음밥',  '신 김치로 만드는 고소한 볶음밥',    15, RecipeDifficulty.easy,   RecipeType.main),
  ],
  'lunch': [
    _RecipeEntry('🍲', '된장찌개',    '집에서 뚝딱, 깊고 구수한 맛',        20, RecipeDifficulty.easy,   RecipeType.soup),
    _RecipeEntry('🌶️', '김치찌개',    '얼큰하고 시원한 국물 한 냄비',       25, RecipeDifficulty.easy,   RecipeType.soup),
    _RecipeEntry('🥩', '불고기',      '달콤한 간장 소고기구이',             30, RecipeDifficulty.easy,   RecipeType.main),
    _RecipeEntry('🍝', '잡채',        '당면과 채소의 달달한 조화',          40, RecipeDifficulty.medium, RecipeType.main),
    _RecipeEntry('🫘', '두부조림',    '밥 한 공기 부르는 바삭한 간장 두부', 20, RecipeDifficulty.easy,   RecipeType.side),
    _RecipeEntry('🍛', '카레라이스',  '채소 듬뿍 집밥 카레',               35, RecipeDifficulty.easy,   RecipeType.main),
    _RecipeEntry('🍳', '오므라이스',  '달콤한 케첩 소스 계란 덮밥',         20, RecipeDifficulty.easy,   RecipeType.main),
    _RecipeEntry('🍚', '비빔밥',      '냉장고 남은 채소로 뚝딱',            20, RecipeDifficulty.easy,   RecipeType.main),
    _RecipeEntry('🥩', '제육볶음',    '밥 도둑 매콤 돼지볶음',              20, RecipeDifficulty.easy,   RecipeType.main),
    _RecipeEntry('🫕', '순두부찌개',  '부드럽고 칼칼한 순두부',             20, RecipeDifficulty.easy,   RecipeType.soup),
  ],
  'snack': [
    _RecipeEntry('🍢', '떡볶이',      '매콤달콤 길거리 간식',               20, RecipeDifficulty.easy,   RecipeType.snack),
    _RecipeEntry('🍢', '어묵볶음',    '달달짭짤 국민 반찬',                 15, RecipeDifficulty.easy,   RecipeType.side),
    _RecipeEntry('🥒', '오이무침',    '아삭하고 시원한 여름반찬',           10, RecipeDifficulty.easy,   RecipeType.side),
    _RecipeEntry('🍜', '라볶이',      '라면 떡볶이 합체 별미',              15, RecipeDifficulty.easy,   RecipeType.main),
    _RecipeEntry('🥬', '겉절이',      '갓 버무린 생배추김치',               10, RecipeDifficulty.easy,   RecipeType.side),
    _RecipeEntry('🥔', '감자전',      '바삭한 감자 부침개',                 20, RecipeDifficulty.easy,   RecipeType.snack),
    _RecipeEntry('🍃', '호박전',      '부드러운 애호박 부침개',             15, RecipeDifficulty.easy,   RecipeType.snack),
    _RecipeEntry('🌿', '파전',        '고소한 파 부침개',                   20, RecipeDifficulty.easy,   RecipeType.snack),
    _RecipeEntry('🍙', '주먹밥',      '참치·김치 속 넣은 한 입 주먹밥',    15, RecipeDifficulty.easy,   RecipeType.snack),
    _RecipeEntry('🥜', '견과류 강정', '달콤바삭 집에서 만드는 견과 강정',   15, RecipeDifficulty.easy,   RecipeType.snack),
  ],
  'dinner': [
    _RecipeEntry('🥩', '제육볶음',    '밥 도둑 매콤 돼지볶음',              20, RecipeDifficulty.easy,   RecipeType.main),
    _RecipeEntry('🍗', '닭갈비',      '춘천식 매콤달콤 닭볶음',             30, RecipeDifficulty.medium, RecipeType.main),
    _RecipeEntry('🍗', '닭볶음탕',    '칼칼하게 끓인 닭도리탕',             45, RecipeDifficulty.medium, RecipeType.soup),
    _RecipeEntry('🥘', '부대찌개',    '소시지 햄 가득 부대찌개',            30, RecipeDifficulty.easy,   RecipeType.soup),
    _RecipeEntry('🫕', '순두부찌개',  '부드럽고 칼칼한 순두부',             20, RecipeDifficulty.easy,   RecipeType.soup),
    _RecipeEntry('🐟', '참치김치볶음밥', '참치캔으로 만드는 간편식',        15, RecipeDifficulty.easy,   RecipeType.main),
    _RecipeEntry('🥓', '삼겹살구이',  '두툼하게 구운 삼겹살',               20, RecipeDifficulty.easy,   RecipeType.main),
    _RecipeEntry('🍖', '갈비찜',      '명절 단골 감칠맛 찜',                90, RecipeDifficulty.hard,   RecipeType.main),
    _RecipeEntry('🐠', '고등어조림',  '칼칼하게 졸인 집밥 고등어',          25, RecipeDifficulty.easy,   RecipeType.main),
  ],
  'lateNight': [
    _RecipeEntry('🍳', '계란볶음밥',     '야밤에 혼자 뚝딱, 든든한 한 그릇', 10, RecipeDifficulty.easy,   RecipeType.main),
    _RecipeEntry('🐟', '참치김치볶음밥', '참치캔으로 만드는 간편식',         15, RecipeDifficulty.easy,   RecipeType.main),
    _RecipeEntry('🥘', '부대찌개',       '소시지 햄 가득 부대찌개',          30, RecipeDifficulty.easy,   RecipeType.soup),
    _RecipeEntry('🍢', '떡볶이',         '매콤달콤 길거리 간식',              20, RecipeDifficulty.easy,   RecipeType.snack),
    _RecipeEntry('🍜', '라볶이',         '라면 떡볶이 합체 별미',             15, RecipeDifficulty.easy,   RecipeType.main),
    _RecipeEntry('🫘', '두부조림',       '바삭한 두부에 간장양념',            20, RecipeDifficulty.easy,   RecipeType.side),
    _RecipeEntry('🍢', '어묵볶음',       '야밤 출출할 때 딱인 매콤달달 어묵', 15, RecipeDifficulty.easy,   RecipeType.side),
    _RecipeEntry('🍜', '신라면',         '야밤에 끓여먹는 매운 라면의 정석',  15, RecipeDifficulty.easy,   RecipeType.main),
    _RecipeEntry('🍗', '양념치킨',       '달콤매콤 집에서 만드는 야식 치킨',  30, RecipeDifficulty.medium, RecipeType.main),
    _RecipeEntry('🥓', '김치삼겹 볶음',  '신 김치와 삼겹살 한판 볶기',        20, RecipeDifficulty.easy,   RecipeType.main),
  ],
};

const _periodMeta = <String, ({String emoji, String label})>{
  'breakfast': (emoji: '🌅', label: '아침 추천'),
  'lunch':     (emoji: '☀️', label: '점심 추천'),
  'snack':     (emoji: '🌤', label: '오후 간식 추천'),
  'dinner':    (emoji: '🌆', label: '저녁 추천'),
  'lateNight': (emoji: '🌙', label: '야식 추천'),
};

// ─── 화면 ─────────────────────────────────────────────────────────────────────

/// 시간대별 추천 레시피 화면.
///
/// 홈 시간대 멘트를 탭하면 진입한다. 해당 시간대 레시피 풀에서
/// 랜덤 1개를 뽑아 백엔드/캐시/AI 순서로 조회하며, 새로고침 버튼으로
/// 중복 없이 다른 요리를 선택할 수 있다.
class TimeBasedRecipeScreen extends ConsumerStatefulWidget {
  const TimeBasedRecipeScreen({super.key, required this.period});

  /// 'breakfast' | 'lunch' | 'snack' | 'dinner' | 'lateNight'
  final String period;

  @override
  ConsumerState<TimeBasedRecipeScreen> createState() =>
      _TimeBasedRecipeScreenState();
}

class _TimeBasedRecipeScreenState
    extends ConsumerState<TimeBasedRecipeScreen> {
  _RecipeEntry? _currentEntry;
  Recipe? _recipe;
  bool _isLoading = false;
  String? _error;
  final Set<int> _usedIndices = {};

  List<_RecipeEntry> get _pool =>
      _periodRecipes[widget.period] ?? _periodRecipes['dinner']!;

  @override
  void initState() {
    super.initState();
    _loadNext();
  }

  Future<void> _loadNext() async {
    final pool = _pool;
    if (_usedIndices.length >= pool.length) _usedIndices.clear();

    final available = List.generate(pool.length, (i) => i)
        .where((i) => !_usedIndices.contains(i))
        .toList();
    final idx = available[Random().nextInt(available.length)];
    _usedIndices.add(idx);
    final entry = pool[idx];

    setState(() {
      _currentEntry = entry;
      _recipe = null;
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = await ref.read(recipeRepositoryProvider.future);
      final result = await repo.generateByName(entry.title);
      if (!mounted) return;
      result.when(
        success: (r) => setState(() {
          _recipe = r;
          _isLoading = false;
        }),
        failure: (e) => setState(() {
          _error = e.message;
          _isLoading = false;
        }),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '레시피를 불러오지 못했어요.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta =
        _periodMeta[widget.period] ?? (emoji: '🍽️', label: '추천 레시피');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TwemojiIcon(meta.emoji, size: 20),
            const SizedBox(width: 8),
            Text(meta.label, style: AppTheme.screenTitleStyle),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '다른 레시피',
            onPressed: _isLoading ? null : _loadNext,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _LoadingView(entry: _currentEntry);
    if (_error != null) return _ErrorView(message: _error!, onRetry: _loadNext);
    if (_recipe != null) {
      return _RecipeCard(
        entry: _currentEntry!,
        recipe: _recipe!,
        onViewFull: () =>
            context.push('/recipe/${_recipe!.id}', extra: _recipe),
        onRefresh: _loadNext,
      );
    }
    return const SizedBox.shrink();
  }
}

// ─── 로딩 뷰 ──────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView({this.entry});

  final _RecipeEntry? entry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry != null) ...[
            TwemojiIcon(entry!.emoji, size: 64),
            const SizedBox(height: 16),
            Text(
              entry!.title,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textStrong,
              ),
            ),
            const SizedBox(height: 24),
          ],
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            '레시피를 불러오는 중...',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              color: AppTheme.iconSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 에러 뷰 ──────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😕', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                color: AppTheme.iconSubtle,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 레시피 카드 ───────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.entry,
    required this.recipe,
    required this.onViewFull,
    required this.onRefresh,
  });

  final _RecipeEntry entry;
  final Recipe recipe;
  final VoidCallback onViewFull;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final ingredients = recipe.ingredients;
    final previewCount = ingredients.length.clamp(0, 4);
    final extraCount = ingredients.length - previewCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 헤더 카드 ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.dividerSubtle,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 or 이모지
                Center(
                  child: recipe.imageUrl != null &&
                          recipe.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            recipe.imageUrl!,
                            width: 180,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                TwemojiIcon(entry.emoji, size: 80),
                          ),
                        )
                      : TwemojiIcon(entry.emoji, size: 80),
                ),
                const SizedBox(height: 16),

                // 제목 + 뱃지
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        recipe.title,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textStrong,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RecipeTypeBadge(recipeType: recipe.recipeType),
                  ],
                ),
                const SizedBox(height: 8),

                // 설명
                Text(
                  recipe.description,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    color: AppTheme.iconSubtle,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),

                // 메타 (시간·난이도·인분)
                Row(
                  children: [
                    _MetaChip(
                      icon: Icons.timer_outlined,
                      label: '${recipe.cookingTimeMinutes}분',
                    ),
                    const SizedBox(width: 8),
                    _MetaChip(
                      icon: Icons.bar_chart_rounded,
                      label: recipe.difficulty.label,
                    ),
                    const SizedBox(width: 8),
                    _MetaChip(
                      icon: Icons.people_outline_rounded,
                      label: '${recipe.servings}인분',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ─── 재료 미리보기 ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.dividerSubtle,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '주요 재료',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textStrong,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ...ingredients.take(previewCount).map(
                          (ing) => _IngredientChip(name: ing.name),
                        ),
                    if (extraCount > 0)
                      _IngredientChip(
                        name: '외 $extraCount가지',
                        isMuted: true,
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ─── 전체 레시피 보기 버튼 ──────────────────────────────────
          FilledButton(
            onPressed: onViewFull,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '전체 레시피 보기',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ─── 다른 레시피 보기 버튼 ──────────────────────────────────
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              '다른 레시피 추천받기',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 보조 위젯 ─────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.iconSubtle),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              color: AppTheme.iconSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({required this.name, this.isMuted = false});

  final String name;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isMuted
            ? AppTheme.backgroundColor
            : AppTheme.primaryColor.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMuted ? AppTheme.dividerSubtle : AppTheme.primaryColor.withAlpha(60),
        ),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          color: isMuted ? AppTheme.iconSubtle : AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
