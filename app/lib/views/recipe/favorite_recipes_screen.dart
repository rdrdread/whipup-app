import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/providers/recipe_providers.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';
import 'package:whipup/widgets/recipe/recipe_card.dart';

/// 찜한 레시피 목록 화면.
///
/// [favoriteRecipesProvider]를 구독하며, 찜 해제 시 목록이 실시간으로 갱신된다.
class FavoriteRecipesScreen extends ConsumerWidget {
  const FavoriteRecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteRecipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 요리 찜', style: AppTheme.screenTitleStyle),
        centerTitle: false,
      ),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (recipes) {
          if (recipes.isEmpty) {
            return const _EmptyFavoritesView();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return _FavoriteRecipeItem(
                recipe: recipe,
                onTap: () => context.push(
                  '/recipe/${recipe.id}',
                  extra: recipe,
                ),
                onUnfavorite: () async {
                  HapticFeedback.lightImpact();
                  final repo =
                      await ref.read(recipeRepositoryProvider.future);
                  await repo.toggleFavorite(recipe.id);
                  ref.invalidate(favoriteRecipesProvider);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('찜이 해제되었어요'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─── 찜 레시피 아이템 ──────────────────────────────────────────────────────────

/// 찜 목록 아이템 — RecipeCard에 찜 해제 버튼을 오버레이한다.
class _FavoriteRecipeItem extends StatelessWidget {
  const _FavoriteRecipeItem({
    required this.recipe,
    required this.onTap,
    required this.onUnfavorite,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RecipeCard(recipe: recipe, onTap: onTap),
        // 찜 해제 버튼
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onUnfavorite,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 20,
                  color: Colors.red.shade300,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 빈 상태 ──────────────────────────────────────────────────────────────────

class _EmptyFavoritesView extends StatelessWidget {
  const _EmptyFavoritesView();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TwemojiIcon('🤍', size: 72),
            const SizedBox(height: 20),
            Text(
              '찜한 레시피가 없어요',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '레시피 상세 화면에서 ❤️ 를 탭하면\n찜 목록에 추가돼요',
              style: tt.bodyMedium?.copyWith(color: AppTheme.iconSubtle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.go('/recipe'),
              icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
              label: const Text('레시피 찾으러 가기'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
