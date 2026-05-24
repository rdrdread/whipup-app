import 'package:flutter/material.dart';
import 'package:whipup/core/extensions/build_context_extensions.dart';

/// 마이페이지 화면.
///
/// - 활동 통계 (Phase 1.0 placeholder)
/// - 리워드 (Phase 1.4)
/// - 칼럼 (Phase 2.6)
/// - 설정 (Phase 1.0 placeholder)
///
/// 레이아웃: `docs/core/screen_layout.md §2.1`
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '마이',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
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
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_rounded,
                    size: 28,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '요리사님 👋',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '냉장고 속 재료로 즐거운 요리!',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── 메뉴 리스트 ──────────────────────────────────────────────
          _MenuItem(
            icon: Icons.emoji_events_outlined,
            label: '리워드',
            badge: 'Phase 1.4',
            onTap: () => context.showComingSoon(),
          ),
          _MenuItem(
            icon: Icons.article_outlined,
            label: '칼럼',
            badge: 'Phase 2.6',
            onTap: () => context.showComingSoon(),
          ),
          _MenuItem(
            icon: Icons.history_rounded,
            label: '나의 기록',
            onTap: () => context.showComingSoon(),
          ),
          const Divider(height: 32),
          _MenuItem(
            icon: Icons.settings_outlined,
            label: '설정',
            onTap: () => context.showComingSoon(),
          ),
          _MenuItem(
            icon: Icons.info_outline_rounded,
            label: '앱 정보',
            onTap: () => context.showComingSoon(),
          ),
        ],
      ),
    );
  }
}

/// 마이 페이지 메뉴 아이템.
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onTap: onTap,
    );
  }
}
