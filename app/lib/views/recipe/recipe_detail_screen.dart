import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/cooking_chat_message.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/providers/cooking_chat_provider.dart';
import 'package:whipup/providers/recipe_providers.dart';
import 'package:whipup/providers/reward_providers.dart';
import 'package:whipup/providers/stock_providers.dart';
import 'dart:math' as math;
import 'package:whipup/widgets/common/twemoji_icon.dart';
import 'package:whipup/widgets/recipe/cooking_step_item.dart';
import 'package:whipup/widgets/recipe/youtube_player_card.dart';
import 'package:whipup/widgets/recipe/flavor_radar.dart';
import 'package:whipup/widgets/recipe/ingredient_check_list.dart';
import 'package:whipup/widgets/recipe/recipe_type_badge.dart';
import 'package:whipup/services/points_service.dart';
import 'package:whipup/widgets/recipe/photo_upload_sheet.dart';
import 'package:whipup/widgets/reward/achievement_unlock_dialog.dart';

/// 레시피 상세 화면 (Phase 1.1).
///
/// 7단계 조리 가이드 + 타이머 + 맛 프로필 + 재료 체크리스트.
/// 레이아웃: `docs/core/screen_layout.md §3.5`
class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.initialRecipe,
  });

  final String recipeId;

  /// 빠른 레시피/시간대별 레시피 플로우에서 직접 전달받은 레시피.
  /// 제공 시 Isar 조회 없이 즉시 화면을 표시한다.
  final Recipe? initialRecipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // extra로 전달된 레시피가 있으면 Isar 조회 없이 바로 표시
    if (initialRecipe != null) {
      return _RecipeDetailContent(recipe: initialRecipe!);
    }

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
  late int _displayServings;
  int? _videoSyncStepIndex;

  @override
  void initState() {
    super.initState();
    _displayServings = widget.recipe.servings;
  }

  @override
  void didUpdateWidget(_RecipeDetailContent old) {
    super.didUpdateWidget(old);
    if (old.recipe.id != widget.recipe.id) {
      _displayServings = widget.recipe.servings;
    }
  }

  void _onVideoTimeUpdate(double t) {
    int? syncIdx;
    final steps = widget.recipe.steps;
    for (int i = 0; i < steps.length; i++) {
      final ts = steps[i].videoTimestampSeconds;
      if (ts != null && ts <= t) syncIdx = i;
    }
    if (syncIdx != _videoSyncStepIndex) {
      setState(() => _videoSyncStepIndex = syncIdx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final recipe = widget.recipe;
    final ownedItemsAsync = ref.watch(filteredStockProvider);
    final ownedItems = ownedItemsAsync.asData?.value ?? [];

    return Scaffold(
      bottomNavigationBar: _CookingChatBar(recipe: recipe),
      body: CustomScrollView(
        slivers: [
          // ─── 히어로 사진 + 패럴랙스 앱바 ────────────────────────────────
          SliverAppBar(
            expandedHeight: recipe.videoUrl != null ? null : 300,
            pinned: true,
            stretch: recipe.videoUrl == null,
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            title: Text(
              recipe.title,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            flexibleSpace: recipe.videoUrl != null
                ? null
                : FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: _FoodHeroImage(recipe: recipe),
                    stretchModes: const [StretchMode.zoomBackground],
                  ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: '레시피 편집',
                onPressed: () async {
                  final updated = await context.push<Recipe>(
                    '/recipe/${recipe.id}/edit',
                    extra: recipe,
                  );
                  if (updated != null && mounted) {
                    if (context.canPop()) context.pop();
                    context.push('/recipe/${updated.id}', extra: updated); // ignore: use_build_context_synchronously
                  }
                },
              ),
              _FavoriteButton(recipeId: recipe.id),
            ],
          ),

          // ─── 영상 플레이어 (videoUrl 있을 때) ────────────────────────────
          if (recipe.videoUrl != null)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: YouTubePlayerCard(
                  videoUrl: recipe.videoUrl!,
                  onTimeUpdate: _onVideoTimeUpdate,
                ),
              ),
            ),

          // ─── 콘텐츠 ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ─── 배지 + 제목 + 시간 + 인분 + 설명 ─────────────────
                  RecipeTypeBadge(recipeType: recipe.recipeType),
                  const SizedBox(height: 8),
                  Text(
                    recipe.title,
                    style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${recipe.cookingTimeMinutes}분 · ${recipe.difficulty.label}',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  _ServingsStepper(
                    value: _displayServings,
                    enabled: !_isCompleted,
                    onChanged: (v) => setState(() => _displayServings = v),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  // ─── 맛 프로필 ──────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '🍽️ 맛 프로필',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FlavorRadar(flavorProfile: recipe.flavorProfile, size: 150),

                  const SizedBox(height: 28),

                  // ─── 재료 체크리스트 ─────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '📋 재료',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  IngredientCheckList(
                    ingredients: recipe.ingredients,
                    ownedItems: ownedItems,
                    baseServings: recipe.servings,
                    displayServings: _displayServings,
                  ),

                  const SizedBox(height: 28),

                  // ─── 조리 순서 ──────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '👨‍🍳 조리 순서 (${recipe.totalSteps}단계)',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...recipe.steps.asMap().entries.map(
                    (e) => CookingStepItem(
                      step: e.value,
                      isVideoSync: _videoSyncStepIndex == e.key,
                    ),
                  ),

                  // ─── 요리 과학 ──────────────────────────────────────
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
                          Icon(Icons.science_outlined, size: 18, color: cs.tertiary),
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

                  // ─── 요리 완료 버튼 ─────────────────────────────────
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
            ),
          ),
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

    // 사진 등록 유도 바텀시트
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    final photoPath = await PhotoUploadSheet.show(context, widget.recipe.title);
    if (photoPath != null) {
      await PointsService.addPhotoPoints();
      final repo = await ref.read(recipeRepositoryProvider.future);
      await repo.updateCompletionData(widget.recipe.id, photoPath: photoPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('📸 사진 등록 완료! +30P 적립됐어요'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    // 리워드 화면으로 이동
    if (!mounted) return;
    context.push('/my/reward'); // ignore: use_build_context_synchronously
  }
}

/// 인분 수 조절 스테퍼 위젯.
class _ServingsStepper extends StatelessWidget {
  const _ServingsStepper({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: enabled && value > 1,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(value - 1);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$value인분',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: enabled && value < 20,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(value + 1);
            },
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? cs.primary : cs.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// ─── 요리 도우미 채팅 바 ────────────────────────────────────────────────────────

/// 레시피 상세 하단에 고정되는 AI 요리 도우미 채팅 입력 바.
class _CookingChatBar extends ConsumerStatefulWidget {
  const _CookingChatBar({required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<_CookingChatBar> createState() => _CookingChatBarState();
}

class _CookingChatBarState extends ConsumerState<_CookingChatBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _focusNode.unfocus();
    await ref.read(cookingChatProvider(widget.recipe.id).notifier).ask(
          recipe: widget.recipe,
          question: text,
        );
  }

  void _openHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChatHistorySheet(recipe: widget.recipe),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final chatState = ref.watch(cookingChatProvider(widget.recipe.id));

    final assistantMessages =
        chatState.messages.where((m) => m.role == ChatRole.assistant).toList();
    final lastReply =
        assistantMessages.isNotEmpty ? assistantMessages.last : null;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 마지막 AI 답변 미리보기 ───────────────────────────
            if (lastReply != null)
              GestureDetector(
                onTap: () => _openHistory(context),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Text('🤖', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          lastReply.content,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSecondaryContainer,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: cs.onSecondaryContainer.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
            // ─── 에러 메시지 ────────────────────────────────────────
            if (chatState.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '⚠️ ${chatState.error}',
                  style: tt.bodySmall?.copyWith(color: cs.error),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // ─── 입력 바 ─────────────────────────────────────────────
            Row(
              children: [
                if (chatState.messages.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                      color: cs.primary,
                    ),
                    tooltip: '대화 내역 보기',
                    onPressed: () => _openHistory(context),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !chatState.isLoading,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: '요리하다 궁금한 점이 있으신가요? 🤖',
                      hintStyle: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: tt.bodySmall,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: chatState.isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            size: 18,
                            color: cs.primary,
                          ),
                          tooltip: '전송',
                          padding: EdgeInsets.zero,
                          onPressed: _send,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 전체 대화 내역을 보여주는 바텀시트.
class _ChatHistorySheet extends ConsumerStatefulWidget {
  const _ChatHistorySheet({required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<_ChatHistorySheet> createState() => _ChatHistorySheetState();
}

class _ChatHistorySheetState extends ConsumerState<_ChatHistorySheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(cookingChatProvider(widget.recipe.id).notifier).ask(
          recipe: widget.recipe,
          question: text,
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final chatState = ref.watch(cookingChatProvider(widget.recipe.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // ─── 핸들 ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ─── 헤더 ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '요리 도우미',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(cookingChatProvider(widget.recipe.id).notifier)
                        .clear();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    '대화 초기화',
                    style: tt.labelSmall?.copyWith(color: cs.error),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ─── 메시지 목록 ─────────────────────────────────────────
          Expanded(
            child: chatState.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('👨‍🍳', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          '요리하다 궁금한 점을 물어보세요!',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '예) "마늘을 언제 넣어야 하나요?"\n"불 세기는 어떻게 조절하나요?"',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: chatState.messages.length,
                    itemBuilder: (_, i) =>
                        _ChatBubble(message: chatState.messages[i]),
                  ),
          ),
          // ─── 로딩 인디케이터 ─────────────────────────────────────
          if (chatState.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI가 답변 중...',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          // ─── 에러 메시지 ─────────────────────────────────────────
          if (chatState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '⚠️ ${chatState.error}',
                style: tt.bodySmall?.copyWith(color: cs.error),
              ),
            ),
          // ─── 입력 영역 ───────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !chatState.isLoading,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: '질문을 입력하세요...',
                        hintStyle: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: tt.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: chatState.isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          )
                        : FilledButton(
                            onPressed: _send,
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: const CircleBorder(),
                            ),
                            child: const Icon(Icons.send_rounded, size: 18),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 개별 채팅 메시지 말풍선.
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final CookingChatMessage message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isUser = message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const Text('🤖', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser ? cs.primary : cs.secondaryContainer,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.content,
                style: tt.bodySmall?.copyWith(
                  color: isUser ? cs.onPrimary : cs.onSecondaryContainer,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

// ─── 음식 사진 히어로 위젯 ────────────────────────────────────────────────────

/// 장식용 이모지 스펙.
class _DecorSpec {
  const _DecorSpec(this.emoji, this.alignment, this.size, this.opacity);
  final String emoji;
  final Alignment alignment;
  final double size;
  final double opacity;
}

/// 레시피 타입별 음식 일러스트 히어로 위젯.
///
/// SliverAppBar.flexibleSpace 안에서 전체 너비로 표시된다.
/// CustomPainter로 접시·스팀·스파클을 그리고, 타입별 이모지와 그라디언트로 식욕을 자극한다.
class _FoodHeroImage extends StatelessWidget {
  const _FoodHeroImage({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final gradColors = _gradientColors(recipe.recipeType);
    final mainEmoji = _recipeEmoji(recipe.recipeType);
    final decors = _decorEmojis(recipe.recipeType);
    final steam = _hasSteam(recipe.recipeType);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 타입별 짙은 그라디언트 배경
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // 접시·스팀·스파클 일러스트
        CustomPaint(painter: _FoodIllustrationPainter(hasSteam: steam)),
        // 배경 장식 이모지
        for (final d in decors)
          Align(
            alignment: d.alignment,
            child: Opacity(
              opacity: d.opacity,
              child: TwemojiIcon(d.emoji, size: d.size),
            ),
          ),
        // 접시 위 대표 이모지
        Align(
          alignment: const Alignment(0, 0.18),
          child: TwemojiIcon(mainEmoji, size: 100),
        ),
        // 상단 그라디언트 (앱바 아이콘 가독성)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x99000000), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment(0, 0.5),
            ),
          ),
        ),
        // 하단 그라디언트 (콘텐츠 전환 경계)
        const Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0x66000000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static List<Color> _gradientColors(recipeType) {
    final t = recipeType.toString();
    if (t.contains('soup'))    return [const Color(0xFFFF7043), const Color(0xFF8D1F00)];
    if (t.contains('main'))    return [const Color(0xFFFFB300), const Color(0xFFBF360C)];
    if (t.contains('side'))    return [const Color(0xFF66BB6A), const Color(0xFF1B5E20)];
    if (t.contains('snack'))   return [const Color(0xFFFF8A65), const Color(0xFFAD1457)];
    if (t.contains('dessert')) return [const Color(0xFFCE93D8), const Color(0xFF4A148C)];
    if (t.contains('drink'))   return [const Color(0xFF4DB6AC), const Color(0xFF004D40)];
    if (t.contains('sauce'))   return [const Color(0xFFA1887F), const Color(0xFF3E2723)];
    return [const Color(0xFFFFAB40), const Color(0xFFBF360C)];
  }

  static String _recipeEmoji(recipeType) {
    final t = recipeType.toString();
    if (t.contains('soup'))    return '🍲';
    if (t.contains('main'))    return '🍚';
    if (t.contains('side'))    return '🥗';
    if (t.contains('snack'))   return '🍢';
    if (t.contains('dessert')) return '🍮';
    if (t.contains('drink'))   return '🍵';
    return '🍽️';
  }

  static bool _hasSteam(recipeType) {
    final t = recipeType.toString();
    return t.contains('soup') || t.contains('main') || t.contains('drink');
  }

  static List<_DecorSpec> _decorEmojis(recipeType) {
    final t = recipeType.toString();
    if (t.contains('soup')) {
      return const [
        _DecorSpec('🌶️', Alignment(-0.82, -0.72), 54, 0.20),
        _DecorSpec('🧄', Alignment(0.82, -0.65), 46, 0.18),
        _DecorSpec('🌿', Alignment(-0.75, 0.72), 42, 0.16),
        _DecorSpec('🫙', Alignment(0.78, 0.76), 50, 0.14),
      ];
    }
    if (t.contains('main')) {
      return const [
        _DecorSpec('🌾', Alignment(-0.82, -0.72), 50, 0.20),
        _DecorSpec('🥢', Alignment(0.80, -0.68), 42, 0.18),
        _DecorSpec('🔥', Alignment(0.80, 0.72), 46, 0.16),
        _DecorSpec('🍳', Alignment(-0.76, 0.76), 50, 0.14),
      ];
    }
    if (t.contains('side')) {
      return const [
        _DecorSpec('🌿', Alignment(-0.82, -0.72), 50, 0.20),
        _DecorSpec('🥬', Alignment(0.80, -0.68), 46, 0.18),
        _DecorSpec('🌱', Alignment(-0.76, 0.76), 42, 0.15),
        _DecorSpec('🫒', Alignment(0.80, 0.74), 44, 0.14),
      ];
    }
    if (t.contains('snack')) {
      return const [
        _DecorSpec('✨', Alignment(-0.80, -0.70), 38, 0.22),
        _DecorSpec('🌟', Alignment(0.82, -0.68), 34, 0.22),
        _DecorSpec('⭐', Alignment(0.78, 0.72), 42, 0.18),
        _DecorSpec('🎉', Alignment(-0.76, 0.74), 40, 0.15),
      ];
    }
    if (t.contains('dessert')) {
      return const [
        _DecorSpec('🌸', Alignment(-0.82, -0.70), 46, 0.20),
        _DecorSpec('⭐', Alignment(0.82, -0.66), 38, 0.22),
        _DecorSpec('🌷', Alignment(0.78, 0.74), 42, 0.17),
        _DecorSpec('🍓', Alignment(-0.76, 0.74), 44, 0.16),
      ];
    }
    if (t.contains('drink')) {
      return const [
        _DecorSpec('💧', Alignment(-0.80, -0.70), 38, 0.22),
        _DecorSpec('🌿', Alignment(0.82, -0.68), 46, 0.17),
        _DecorSpec('🧊', Alignment(0.78, 0.72), 42, 0.17),
        _DecorSpec('🍃', Alignment(-0.76, 0.74), 40, 0.15),
      ];
    }
    return const [
      _DecorSpec('✨', Alignment(-0.80, -0.70), 38, 0.20),
      _DecorSpec('🌟', Alignment(0.82, -0.66), 34, 0.20),
    ];
  }
}

/// 접시·스팀·스파클을 캔버스에 직접 그리는 CustomPainter.
class _FoodIllustrationPainter extends CustomPainter {
  const _FoodIllustrationPainter({required this.hasSteam});
  final bool hasSteam;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.62;
    final r = (size.width * 0.24).clamp(70.0, 115.0);
    _drawPlateShadow(canvas, cx, cy, r);
    _drawPlate(canvas, cx, cy, r);
    if (hasSteam) _drawSteam(canvas, cx, cy - r);
    _drawSparkles(canvas, size);
  }

  void _drawPlateShadow(Canvas canvas, double cx, double cy, double r) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.18), width: r * 2.2, height: r * 0.55),
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  void _drawPlate(Canvas canvas, double cx, double cy, double r) {
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    // 접시 본체 — 크림/베이지 방사형 그라디언트로 도자기 질감 표현
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 1.0,
          colors: [Color(0xFFFFF9F0), Color(0xFFF5E8D0), Color(0xFFDFC8A0)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    // 외곽 테두리 (흰색 60%)
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    // 내부 장식 링 (따뜻한 갈색 45%)
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.84,
      Paint()
        ..color = const Color(0xFFC8A878).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    // 왼쪽 상단 글린트 호
    canvas.drawPath(
      Path()..addArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.88), -2.7, 0.9),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawSteam(Canvas canvas, double cx, double plateTopY) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    // 왼쪽 스팀 웨이브
    canvas.drawPath(
      Path()
        ..moveTo(cx - 22, plateTopY)
        ..cubicTo(cx - 38, plateTopY - 18, cx - 8, plateTopY - 34, cx - 22, plateTopY - 52),
      paint,
    );
    // 중앙 스팀 웨이브
    canvas.drawPath(
      Path()
        ..moveTo(cx, plateTopY)
        ..cubicTo(cx + 16, plateTopY - 18, cx - 14, plateTopY - 34, cx, plateTopY - 54),
      paint,
    );
    // 오른쪽 스팀 웨이브
    canvas.drawPath(
      Path()
        ..moveTo(cx + 22, plateTopY)
        ..cubicTo(cx + 38, plateTopY - 18, cx + 8, plateTopY - 34, cx + 22, plateTopY - 52),
      paint,
    );
  }

  void _drawSparkles(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    _drawStar(canvas, paint, Offset(size.width * 0.12, size.height * 0.18), 7);
    _drawStar(canvas, paint, Offset(size.width * 0.88, size.height * 0.22), 5.5);
    _drawStar(canvas, paint, Offset(size.width * 0.10, size.height * 0.78), 5);
    _drawStar(canvas, paint, Offset(size.width * 0.90, size.height * 0.75), 6.5);
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double r) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8 - math.pi / 2;
      final dist = i.isEven ? r : r * 0.42;
      final x = center.dx + dist * math.cos(angle);
      final y = center.dy + dist * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FoodIllustrationPainter old) => old.hasSteam != hasSteam;
}

// ─── 찜 버튼 ──────────────────────────────────────────────────────────────────

/// 레시피 상세 앱바용 찜 버튼.
///
/// 찜 추가/해제 시 오버레이 애니메이션을 표시하고
/// [favoriteRecipesProvider]를 구독해 아이콘 상태를 실시간 반영한다.
class _FavoriteButton extends ConsumerStatefulWidget {
  const _FavoriteButton({required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<_FavoriteButton> {
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showAnimation(bool adding) {
    _overlayEntry?.remove();
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (_) => _HeartAnimOverlay(
        adding: adding,
        onComplete: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  Future<void> _handleTap(bool isFavorite) async {
    HapticFeedback.mediumImpact();
    _showAnimation(!isFavorite); // 추가 시 ❤️, 해제 시 💔
    final repo = await ref.read(recipeRepositoryProvider.future);
    await repo.toggleFavorite(widget.recipeId);
    ref.invalidate(favoriteRecipesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoriteRecipesProvider);
    final isFavorite =
        favoritesAsync.asData?.value.any((r) => r.id == widget.recipeId) ??
            false;

    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: anim,
          child: child,
        ),
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(isFavorite),
          color: isFavorite ? Colors.red.shade300 : null,
        ),
      ),
      tooltip: isFavorite ? '찜 해제' : '찜',
      onPressed: () => _handleTap(isFavorite),
    );
  }
}

/// 찜 추가/해제 시 화면 중앙에 표시되는 하트 오버레이 애니메이션.
class _HeartAnimOverlay extends StatefulWidget {
  const _HeartAnimOverlay({
    required this.adding,
    required this.onComplete,
  });

  final bool adding;
  final VoidCallback onComplete;

  @override
  State<_HeartAnimOverlay> createState() => _HeartAnimOverlayState();
}

class _HeartAnimOverlayState extends State<_HeartAnimOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    final duration =
        widget.adding ? const Duration(milliseconds: 900) : const Duration(milliseconds: 650);
    _ctrl = AnimationController(duration: duration, vsync: this);

    _scale = widget.adding
        ? Tween(begin: 0.2, end: 1.5).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut))
        : Tween(begin: 0.8, end: 1.2).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _opacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(widget.adding ? 0.55 : 0.35, 1.0),
      ),
    );

    _ctrl.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: _scale.value,
              child: Text(
                widget.adding ? '❤️' : '💔',
                style: const TextStyle(fontSize: 80),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

