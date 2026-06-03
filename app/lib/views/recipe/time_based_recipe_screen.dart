import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/recipe_type.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/widgets/recipe/recipe_type_badge.dart';

/// 시간대별 추천 레시피 목록 화면.
///
/// 홈의 시간대 감성 멘트를 탭하면 진입한다.
/// 각 카드를 탭하면 [QuickRecipeScreen]으로 이동해 AI 레시피를 생성한다.
class TimeBasedRecipeScreen extends StatelessWidget {
  const TimeBasedRecipeScreen({super.key, required this.period});

  /// 'breakfast' | 'lunch' | 'snack' | 'dinner' | 'lateNight'
  final String period;

  static const _periodMeta = {
    'breakfast': (emoji: '🌅', label: '아침 추천'),
    'lunch':     (emoji: '☀️', label: '점심 추천'),
    'snack':     (emoji: '🌤', label: '오후 간식 추천'),
    'dinner':    (emoji: '🌆', label: '저녁 추천'),
    'lateNight': (emoji: '🌙', label: '야식 추천'),
  };

  static const _periodRecipes = <String, List<_RecipeEntry>>{
    'breakfast': [
      _RecipeEntry('🥚', '계란말이',    '아침 도시락 단골 메뉴',     15, RecipeDifficulty.easy,  RecipeType.side),
      _RecipeEntry('🌿', '미역국',      '담백하고 시원한 생일국',     30, RecipeDifficulty.easy,  RecipeType.soup),
      _RecipeEntry('🍜', '콩나물국',    '시원하고 깔끔한 해장국',     15, RecipeDifficulty.easy,  RecipeType.soup),
      _RecipeEntry('🥬', '시금치나물',  '참기름 향 솔솔 무침',        10, RecipeDifficulty.easy,  RecipeType.side),
      _RecipeEntry('🍳', '계란볶음밥',  '냉장고 털어 만드는 볶음밥',  10, RecipeDifficulty.easy,  RecipeType.main),
      _RecipeEntry('🥚', '계란국',      '5분 만에 뚝딱 간단국',        5, RecipeDifficulty.easy,  RecipeType.soup),
    ],
    'lunch': [
      _RecipeEntry('🍲', '된장찌개',    '집에서 뚝딱, 깊고 구수한 맛', 20, RecipeDifficulty.easy,   RecipeType.soup),
      _RecipeEntry('🌶️', '김치찌개',    '얼큰하고 시원한 국물 한 냄비', 25, RecipeDifficulty.easy,   RecipeType.soup),
      _RecipeEntry('🥩', '불고기',      '달콤한 간장 소고기구이',       30, RecipeDifficulty.easy,   RecipeType.main),
      _RecipeEntry('🍝', '잡채',        '당면과 채소의 달달한 조화',    40, RecipeDifficulty.medium, RecipeType.main),
      _RecipeEntry('🫘', '두부조림',    '바삭한 두부에 간장양념',       20, RecipeDifficulty.easy,   RecipeType.side),
      _RecipeEntry('🍛', '카레라이스',  '채소 듬뿍 집밥 카레',          35, RecipeDifficulty.easy,   RecipeType.main),
    ],
    'snack': [
      _RecipeEntry('🍢', '떡볶이',      '매콤달콤 길거리 간식',         20, RecipeDifficulty.easy,   RecipeType.snack),
      _RecipeEntry('🍢', '어묵볶음',    '달달짭짤 국민 반찬',           15, RecipeDifficulty.easy,   RecipeType.side),
      _RecipeEntry('🥔', '감자조림',    '짭쪼름 달콤 감자반찬',         25, RecipeDifficulty.easy,   RecipeType.side),
      _RecipeEntry('🫘', '순두부찌개',  '부드럽고 칼칼한 순두부',       20, RecipeDifficulty.easy,   RecipeType.soup),
      _RecipeEntry('🥒', '오이무침',    '아삭하고 시원한 여름반찬',     10, RecipeDifficulty.easy,   RecipeType.side),
    ],
    'dinner': [
      _RecipeEntry('🥩', '제육볶음',    '밥 도둑 매콤 돼지볶음',        20, RecipeDifficulty.easy,   RecipeType.main),
      _RecipeEntry('🍗', '닭갈비',      '춘천식 매콤달콤 닭볶음',       30, RecipeDifficulty.medium, RecipeType.main),
      _RecipeEntry('🍗', '닭볶음탕',    '칼칼하게 끓인 닭도리탕',       45, RecipeDifficulty.medium, RecipeType.soup),
      _RecipeEntry('🥘', '부대찌개',    '소시지 햄 가득 부대찌개',      30, RecipeDifficulty.easy,   RecipeType.soup),
      _RecipeEntry('🫕', '순두부찌개',  '부드럽고 칼칼한 순두부',       20, RecipeDifficulty.easy,   RecipeType.soup),
      _RecipeEntry('🐟', '참치김치볶음밥', '참치캔으로 만드는 간편식',  15, RecipeDifficulty.easy,   RecipeType.main),
    ],
    'lateNight': [
      _RecipeEntry('🍳', '계란볶음밥',  '냉장고 털어 만드는 볶음밥',    10, RecipeDifficulty.easy,  RecipeType.main),
      _RecipeEntry('🐟', '참치김치볶음밥', '참치캔으로 만드는 간편식',  15, RecipeDifficulty.easy,  RecipeType.main),
      _RecipeEntry('🥚', '계란국',      '5분 만에 뚝딱 간단국',          5, RecipeDifficulty.easy,  RecipeType.soup),
      _RecipeEntry('🥘', '부대찌개',    '소시지 햄 가득 부대찌개',      30, RecipeDifficulty.easy,  RecipeType.soup),
      _RecipeEntry('🍢', '떡볶이',      '매콤달콤 길거리 간식',         20, RecipeDifficulty.easy,  RecipeType.snack),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final meta = _periodMeta[period] ?? (emoji: '🍽️', label: '추천 레시피');
    final recipes = _periodRecipes[period] ?? [];
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(meta.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(meta.label, style: AppTheme.screenTitleStyle),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: recipes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final r = recipes[i];
          return _RecipeCard(
            entry: r,
            onTap: () => context.push(
              '/recipe/quick',
              extra: {'name': r.title, 'emoji': r.emoji},
            ),
          );
        },
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.entry, required this.onTap});

  final _RecipeEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerSubtle),
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
            Text(entry.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RecipeTypeBadge(recipeType: entry.type),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.description,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${entry.minutes}분 · ${entry.difficulty.label}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

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
