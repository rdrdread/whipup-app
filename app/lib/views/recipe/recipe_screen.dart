import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/recipe_type.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/providers/recipe_providers.dart';
import 'package:whipup/providers/stock_providers.dart';
import 'package:whipup/widgets/recipe/recipe_card.dart';

/// 레시피 추천 화면 (Phase 1.1).
///
/// 재고 재료를 카테고리별로 선택하고 AI 레시피를 추천받는다.
/// 레이아웃: `docs/core/screen_layout.md §3.4`
class RecipeScreen extends ConsumerWidget {
  const RecipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final generatorState = ref.watch(recipeGeneratorProvider);
    final selectedItems = ref.watch(selectedIngredientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '레시피',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            tooltip: '즐겨찾기',
            onPressed: () => context.push('/recipe/favorites'),
          ),
        ],
      ),
      body: generatorState.when(
        data: (recipe) {
          if (recipe != null) {
            // 결과 화면
            return _RecipeResultView(
              onReset: () {
                ref.read(recipeGeneratorProvider.notifier).reset();
                ref.read(selectedIngredientsProvider.notifier).clearAll();
              },
              onViewDetail: (id) => context.push('/recipe/$id'),
            );
          }
          // 재료 선택 화면
          return _IngredientSelectionView();
        },
        loading: () => const _RecipeLoadingView(),
        error: (error, _) => _RecipeErrorView(
          message: error.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.read(recipeGeneratorProvider.notifier).generate(),
        ),
      ),

      // 하단 CTA 버튼 (재료 선택 화면에서만 표시)
      bottomNavigationBar: generatorState.whenOrNull(
        data: (recipe) => recipe == null && selectedItems.isNotEmpty
            ? _RecipeCtaBar(selectedCount: selectedItems.length)
            : null,
      ),
    );
  }
}

// ─── 재료 선택 화면 ─────────────────────────────────────────────────────────────

class _IngredientSelectionView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final stockAsync = ref.watch(filteredStockProvider);

    return stockAsync.when(
      data: (allItems) {
        if (allItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🛒', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 20),
                  Text(
                    '재고가 없어요',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '재료를 먼저 등록해 주세요!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.tonal(
                    onPressed: () => context.push('/stock/add'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('재료 추가하기'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 카테고리별로 재료 그룹화
        final grouped = _groupByCategory(allItems);

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // ─── 선택 헤더 ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Text(
                    '📦 재료 선택',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  _SelectButton(
                    label: '모두 선택',
                    onTap: () => ref
                        .read(selectedIngredientsProvider.notifier)
                        .selectAll(allItems),
                  ),
                  const SizedBox(width: 6),
                  _SelectButton(
                    label: '모두 해제',
                    onTap: () => ref
                        .read(selectedIngredientsProvider.notifier)
                        .clearAll(),
                  ),
                ],
              ),
            ),

            // ─── 카테고리별 재료 칩 (가로 스크롤) ──────────────────
            ...grouped.entries.map((entry) => _CategorySection(
                  category: entry.key,
                  items: entry.value,
                )),

            const SizedBox(height: 8),

            // ─── 옵션 (접이식) ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const _RecipeOptionsPanel(),
            ),

            const SizedBox(height: 80),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('재료를 불러올 수 없습니다: $e')),
    );
  }

  Map<String, List<StockItem>> _groupByCategory(List<StockItem> items) {
    final map = <String, List<StockItem>>{};
    for (final item in items) {
      final key = '${item.category.emoji} ${item.category.label}';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
}

// ─── 카테고리 섹션 ──────────────────────────────────────────────────────────────

class _CategorySection extends ConsumerWidget {
  const _CategorySection({
    required this.category,
    required this.items,
  });

  final String category;
  final List<StockItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            category,
            style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _IngredientChip(item: item),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── 재료 선택 칩 ───────────────────────────────────────────────────────────────

class _IngredientChip extends ConsumerWidget {
  const _IngredientChip({required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isSelected =
        ref.watch(selectedIngredientsProvider.notifier).isSelected(item);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(selectedIngredientsProvider.notifier).toggle(item);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${item.name}  ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)}${item.unit}',
          style: tt.bodySmall?.copyWith(
            color: isSelected ? cs.onPrimary : cs.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── 옵션 패널 ─────────────────────────────────────────────────────────────────

class _RecipeOptionsPanel extends ConsumerStatefulWidget {
  const _RecipeOptionsPanel();

  @override
  ConsumerState<_RecipeOptionsPanel> createState() => _RecipeOptionsPanelState();
}

class _RecipeOptionsPanelState extends ConsumerState<_RecipeOptionsPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final options = ref.watch(recipeOptionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              '옵션',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: cs.onSurfaceVariant,
            ),
            onTap: () => setState(() => _expanded = !_expanded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            dense: true,
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 레시피 종류
                  _OptionRow(
                    label: '레시피 종류',
                    value: _recipeTypeLabel(options.recipeType),
                    onTap: () => _showRecipeTypeDialog(context),
                  ),
                  const SizedBox(height: 8),
                  // 난이도
                  _OptionRow(
                    label: '난이도',
                    value: _difficultyLabel(options.difficulty),
                    onTap: () => _showDifficultyDialog(context),
                  ),
                  const SizedBox(height: 8),
                  // 인분
                  _OptionRow(
                    label: '인분',
                    value: '${options.servings}인분',
                    onTap: () => _showServingsDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _recipeTypeLabel(String? type) {
    if (type == null) return '제한 없음';
    try {
      return RecipeType.values.firstWhere((t) => t.name == type).label;
    } catch (_) {
      return '제한 없음';
    }
  }

  String _difficultyLabel(String? d) {
    if (d == null) return '제한 없음';
    try {
      return RecipeDifficulty.values.firstWhere((v) => v.name == d).label;
    } catch (_) {
      return '제한 없음';
    }
  }

  void _showRecipeTypeDialog(BuildContext context) {
    final options = [null, ...RecipeType.values];
    showDialog<String?>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('레시피 종류'),
        children: options.map((t) {
          return SimpleDialogOption(
            onPressed: () {
              ref.read(recipeOptionsProvider.notifier).setRecipeType(t?.name);
              Navigator.pop(context);
            },
            child: Text(t == null ? '제한 없음' : t.label),
          );
        }).toList(),
      ),
    );
  }

  void _showDifficultyDialog(BuildContext context) {
    final options = [null, ...RecipeDifficulty.values];
    showDialog<String?>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('난이도'),
        children: options.map((d) {
          return SimpleDialogOption(
            onPressed: () {
              ref.read(recipeOptionsProvider.notifier).setDifficulty(d?.name);
              Navigator.pop(context);
            },
            child: Text(d == null ? '제한 없음' : d.label),
          );
        }).toList(),
      ),
    );
  }

  void _showServingsDialog(BuildContext context) {
    showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('인분 수'),
        children: [1, 2, 3, 4, 5, 6].map((s) {
          return SimpleDialogOption(
            onPressed: () {
              ref.read(recipeOptionsProvider.notifier).setServings(s);
              Navigator.pop(context);
            },
            child: Text('$s인분'),
          );
        }).toList(),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(label, style: tt.titleSmall),
          const Spacer(),
          Text(
            value,
            style: tt.bodyMedium?.copyWith(color: cs.primary),
          ),
          const SizedBox(width: 4),
          Icon(Icons.expand_more_rounded, size: 18, color: cs.primary),
        ],
      ),
    );
  }
}

// ─── 선택 버튼 ──────────────────────────────────────────────────────────────────

class _SelectButton extends StatelessWidget {
  const _SelectButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0x992C2C2C),
          ),
        ),
      ),
    );
  }
}

// ─── CTA 바 ────────────────────────────────────────────────────────────────────

class _RecipeCtaBar extends ConsumerWidget {
  const _RecipeCtaBar({required this.selectedCount});

  final int selectedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(recipeGeneratorProvider.notifier).generate();
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              '재료 $selectedCount개로 레시피 추천 받기 🍳',
              style: tt.labelLarge?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 로딩 화면 ─────────────────────────────────────────────────────────────────

class _RecipeLoadingView extends StatelessWidget {
  const _RecipeLoadingView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            Text(
              '맛있는 레시피를 찾고 있어요 ✨',
              style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'AI가 재료 조합을 분석하는 중...',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 에러 화면 ─────────────────────────────────────────────────────────────────

class _RecipeErrorView extends StatelessWidget {
  const _RecipeErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😅', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              '앗, 뭔가 엎질렀어요',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 결과 화면 ─────────────────────────────────────────────────────────────────

class _RecipeResultView extends ConsumerWidget {
  const _RecipeResultView({
    required this.onReset,
    required this.onViewDetail,
  });

  final VoidCallback onReset;
  final void Function(String recipeId) onViewDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = ref.watch(recipeGeneratorProvider).asData?.value;
    final tt = Theme.of(context).textTheme;

    if (recipe == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '추천 레시피',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        RecipeCard(
          recipe: recipe,
          onTap: () => onViewDetail(recipe.id),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onReset,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('다른 레시피 추천받기'),
        ),
      ],
    );
  }
}
