import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whipup/models/achievement.dart';
import 'package:whipup/models/user_reward_stats.dart';
import 'package:whipup/providers/reward_providers.dart';
import 'package:whipup/widgets/reward/achievement_card.dart';
import 'package:whipup/widgets/reward/achievement_unlock_dialog.dart';

/// 리워드 대시보드 화면 (Phase 1.4).
///
/// - 연속 기록 카드
/// - 활동 통계 (총 요리/재료/타입)
/// - 업적 그리드 (달성/미달성)
///
/// 레이아웃: `docs/features/reward_system.md §5.1`
class RewardScreen extends ConsumerStatefulWidget {
  const RewardScreen({super.key});

  @override
  ConsumerState<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends ConsumerState<RewardScreen> {
  @override
  void initState() {
    super.initState();
    // 앱 일별 진입 이벤트 처리
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleDailyOpen());
  }

  Future<void> _handleDailyOpen() async {
    final repoAsync = ref.read(rewardRepositoryProvider);
    final repo = await repoAsync.whenOrNull(data: (r) async => r);
    if (repo == null) return;

    final result = await repo.onDailyOpen();
    final unlocked = result.valueOrNull ?? [];

    if (unlocked.isNotEmpty && mounted) {
      ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlocked);
      for (final achievement in unlocked) {
        if (mounted) {
          await AchievementUnlockDialog.show(context, achievement);
        }
      }
      ref.read(newlyUnlockedAchievementsProvider.notifier).clear();
      ref.invalidate(achievementsProvider);
      ref.invalidate(rewardStatsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final statsAsync = ref.watch(rewardStatsProvider);
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '나의 기록',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: statsAsync.when(
        data: (stats) => _Body(stats: stats, achievementsAsync: achievementsAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.stats,
    required this.achievementsAsync,
  });

  final UserRewardStats stats;
  final AsyncValue<List<Achievement>> achievementsAsync;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── 연속 기록 카드 ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔥 연속 기록',
                    style: tt.titleSmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${stats.currentStreak}',
                        style: tt.displaySmall?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '일 연속 요리!',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '최장: ${stats.longestStreak}일',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ─── 활동 통계 ────────────────────────────────────────────────
        Text(
          '📊 활동 통계',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: '총 요리',
                value: '${stats.totalRecipesCompleted}',
                unit: '회',
                emoji: '🍳',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: '등록 재료',
                value: '${stats.totalStocksAdded}',
                unit: '개',
                emoji: '🥬',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: '시도 종류',
                value: '${stats.uniqueRecipeTypeCount}',
                unit: '종',
                emoji: '🗺️',
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ─── 업적 ────────────────────────────────────────────────────
        Text(
          '🏆 업적',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        achievementsAsync.when(
          data: (achievements) {
            final unlocked =
                achievements.where((a) => a.isUnlocked).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked / ${achievements.length}개 달성',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) => AchievementCard(
                    achievement: achievements[index],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('업적 조회 실패: $e'),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── 통계 카드 ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.emoji,
  });

  final String label;
  final String value;
  final String unit;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: tt.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          Text(
            label,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
