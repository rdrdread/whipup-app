import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/providers/reward_providers.dart';

/// 마이페이지 화면.
///
/// - 활동 통계 (Phase 1.4)
/// - 나의 기록/리워드 (Phase 1.4)
/// - 칼럼 (Phase 2.6)
/// - 설정
///
/// 레이아웃: `docs/core/screen_layout.md §2.1`
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final statsAsync = ref.watch(rewardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '마이',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 프로필 영역 ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(
                    Icons.person_rounded,
                    size: 28,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '요리사님 👋',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      statsAsync.when(
                        data: (stats) => Text(
                          stats.currentStreak > 0
                              ? '🔥 ${stats.currentStreak}일 연속 요리 중!'
                              : '냉장고 속 재료로 즐거운 요리!',
                          style: tt.bodySmall,
                        ),
                        loading: () => Text(
                          '냉장고 속 재료로 즐거운 요리!',
                          style: tt.bodySmall,
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── 활동 요약 (소형) ─────────────────────────────────────────
          statsAsync.when(
            data: (stats) => Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatMini(
                    value: '${stats.totalRecipesCompleted}',
                    label: '총 요리',
                  ),
                  _Divider(),
                  _StatMini(
                    value: '${stats.totalStocksAdded}',
                    label: '등록 재료',
                  ),
                  _Divider(),
                  _StatMini(
                    value: '${stats.longestStreak}일',
                    label: '최장 연속',
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // ─── 메뉴 리스트 ──────────────────────────────────────────────
          _MenuItem(
            icon: Icons.emoji_events_outlined,
            label: '나의 기록',
            subtitle: '업적 & 활동 통계',
            onTap: () => context.push('/my/reward'),
          ),
          _MenuItem(
            icon: Icons.camera_alt_outlined,
            label: '영수증 스캔',
            subtitle: '영수증 촬영으로 재료 추가',
            onTap: () => context.push('/camera'),
          ),
          _MenuItem(
            icon: Icons.mic_outlined,
            label: '음성 재료 입력',
            subtitle: '말로 재료를 추가해요',
            onTap: () => context.push('/voice'),
          ),
          _MenuItem(
            icon: Icons.article_outlined,
            label: '칼럼',
            badge: 'Phase 2.6',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 24),
          _MenuItem(
            icon: Icons.settings_outlined,
            label: '설정',
            onTap: () => context.push('/my/settings'),
          ),
          _MenuItem(
            icon: Icons.info_outline_rounded,
            label: '앱 정보',
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('후속 버전에서 개발 예정이에요 🚧'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
        Text(
          label,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

/// 마이 페이지 메뉴 아이템.
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(
        label,
        style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge!,
                style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
    );
  }
}
