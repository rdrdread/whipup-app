import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/recipe_type.dart';
import 'package:whipup/providers/recipe_providers.dart';
import 'package:whipup/repositories/recipe_repository.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/widgets/recipe/recipe_type_badge.dart';

/// 완료된 요리 히스토리 화면.
///
/// 요리를 완성한 기록을 날짜 역순으로 표시하며, 사진이 있는 경우 썸네일로 보여준다.
class CookingHistoryScreen extends ConsumerWidget {
  const CookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(cookingHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          '했던 요리',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const _EmptyHistory();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: entries.length,
            itemBuilder: (context, i) => _HistoryCard(
              entry: entries[i],
              onTap: () => context.push(
                '/recipe/${entries[i].recipe.id}',
                extra: entries[i].recipe,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🍳', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            '아직 완성한 요리가 없어요',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '레시피를 따라 요리를 완성하면\n여기에 기록이 남아요!',
            style: tt.bodySmall?.copyWith(color: AppTheme.iconGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.onTap});

  final RecipeHistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final recipe = entry.recipe;
    final photo = entry.photoPath;
    final hasPhoto = photo != null && File(photo).existsSync();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 사진 or 이모지 썸네일 ────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: hasPhoto
                  ? Image.file(
                      File(photo),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 90,
                      height: 90,
                      color: cs.primaryContainer.withValues(alpha: 0.4),
                      child: Center(
                        child: Text(
                          _recipeEmoji(recipe.recipeType),
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
            ),

            // ─── 텍스트 정보 ──────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecipeTypeBadge(recipeType: recipe.recipeType),
                    const SizedBox(height: 4),
                    Text(
                      recipe.title,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recipe.cookingTimeMinutes}분 · ${recipe.difficulty.label}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(entry.cookedAt),
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── 화살표 ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 36),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.iconGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _recipeEmoji(RecipeType type) {
    return switch (type) {
      RecipeType.soup => '🍲',
      RecipeType.main => '🍚',
      RecipeType.side => '🥗',
      RecipeType.snack => '🍢',
      RecipeType.dessert => '🍮',
      RecipeType.drink => '🍵',
      RecipeType.sauce => '🫙',
    };
  }

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return '오늘';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}월 ${dt.day}일';
  }
}
