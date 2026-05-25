import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/providers/recipe_providers.dart';
import 'package:whipup/providers/reward_providers.dart';
import 'package:whipup/providers/stock_providers.dart';
import 'package:whipup/widgets/recipe/cooking_step_item.dart';
import 'package:whipup/widgets/recipe/flavor_radar.dart';
import 'package:whipup/widgets/recipe/ingredient_check_list.dart';
import 'package:whipup/widgets/recipe/recipe_type_badge.dart';
import 'package:whipup/widgets/reward/achievement_unlock_dialog.dart';

/// 레시피 상세 화면 (Phase 1.1).
///
/// 7단계 조리 가이드 + 타이머 + 맛 프로필 + 재료 체크리스트.
/// 레이아웃: `docs/core/screen_layout.md §3.5`
class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoAsync = ref.watch(recipeRepositoryProvider);

    return repoAsync.when(
      data: (repository) {
        return FutureBuilder<Recipe?>(
          future: repository.getById(recipeId).then(
                (r) => r.valueOrNull,
              ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final recipe = snapshot.data;
            if (recipe == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('레시피')),
                body: const Center(child: Text('레시피를 찾을 수 없습니다.')),
              );
            }
            return _RecipeDetailContent(recipe: recipe);
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('레시피')),
        body: Center(child: Text('오류: $e')),
      ),
    );
  }
}

class _RecipeDetailContent extends ConsumerStatefulWidget {
  const _RecipeDetailContent({required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<_RecipeDetailContent> createState() =>
      _RecipeDetailContentState();
}

class _RecipeDetailContentState extends ConsumerState<_RecipeDetailContent> {
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final recipe = widget.recipe;
    final ownedItemsAsync = ref.watch(filteredStockProvider);
    final ownedItems = ownedItemsAsync.asData?.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          recipe.title,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // 즐겨찾기 버튼
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            tooltip: '즐겨찾기',
            onPressed: () async {
              HapticFeedback.lightImpact();
              final repo =
                  await ref.read(recipeRepositoryProvider.future);
              await repo.toggleFavorite(recipe.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('즐겨찾기에 추가되었습니다!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 히어로 영역 ─────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                const Text('🍽️', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 8),
                RecipeTypeBadge(recipeType: recipe.recipeType),
                const SizedBox(height: 8),
                Text(
                  recipe.title,
                  style: tt.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '${recipe.cookingTimeMinutes}분 · ${recipe.difficulty.label} · ${recipe.servings}인분',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.description,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ─── 맛 프로필 ──────────────────────────────────────────────
          Text(
            '🍽️ 맛 프로필',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Center(
            child: FlavorRadar(
              flavorProfile: recipe.flavorProfile,
              size: 150,
            ),
          ),

          const SizedBox(height: 28),

          // ─── 재료 체크리스트 ─────────────────────────────────────────
          Text(
            '📋 재료',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          IngredientCheckList(
            ingredients: recipe.ingredients,
            ownedItems: ownedItems,
          ),

          const SizedBox(height: 28),

          // ─── 조리 순서 ──────────────────────────────────────────────
          Text(
            '👨‍🍳 조리 순서 (${recipe.totalSteps}단계)',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...recipe.steps.map(
            (step) => CookingStepItem(step: step),
          ),

          // ─── 요리 과학 ───────────────────────────────────────────────
          if (recipe.scienceNote != null &&
              recipe.scienceNote!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(color: cs.tertiary, width: 4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.science_outlined,
                    size: 18,
                    color: cs.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔬 요리 과학',
                          style: tt.titleSmall?.copyWith(
                            color: cs.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.scienceNote!,
                          style: tt.bodyMedium?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // ─── 요리 완료 버튼 ──────────────────────────────────────────
          if (!_isCompleted)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _onRecipeCompleted,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  '🎉 요리 완성!',
                  style: tt.labelLarge?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✅', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '완성했어요! 맛있게 드세요 😋',
                    style: tt.titleSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _onRecipeCompleted() async {
    HapticFeedback.mediumImpact();
    setState(() => _isCompleted = true);

    // 레시피 완료 이벤트 → Reward 처리
    await handleRecipeCompleted(
      ref,
      widget.recipe.id,
      widget.recipe.recipeType.name,
    );

    // 새로 달성된 업적 팝업 표시
    if (!mounted) return;
    final pending = ref.read(newlyUnlockedAchievementsProvider);
    for (final achievement in pending) {
      if (!mounted) break;
      await AchievementUnlockDialog.show(context, achievement);
    }
    ref.read(newlyUnlockedAchievementsProvider.notifier).clear();
  }
}
