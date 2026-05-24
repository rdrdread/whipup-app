import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/core/extensions/build_context_extensions.dart';
import 'package:whipup/providers/stock_providers.dart';
import 'package:whipup/theme/app_theme.dart';

/// 홈 화면 (대시보드).
///
/// - 대시보드 카드: 전체 재고 현황 + 유통기한 임박
/// - 빠른 레시피 추천: Phase 1.1 (후속 개발중)
/// - 콘텐츠: Phase 2.6 (후속 개발중)
///
/// 레이아웃: `docs/core/screen_layout.md §3.1`
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expiringAsync = ref.watch(expiringStockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WhipUp',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w900,
            fontSize: 26,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.showComingSoon(),
            tooltip: '알림',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.showComingSoon(),
            tooltip: '설정',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 대시보드 카드 ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '우리집 냉장고 현황',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                expiringAsync.when(
                  data: (items) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (items.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppTheme.warningAmber,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '유통기한 임박 ${items.length}개',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...items.take(3).map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '  ${item.category.emoji} ${item.name} — ${item.dDayLabel}',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                            ),
                      ] else
                        const Text(
                          '✅ 유통기한 임박 재료 없음!',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  loading: () => const SizedBox(
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  error: (_, __) => const Text(
                    '불러오는 중 오류 발생',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/stock'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text(
                    '재고 관리 →',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── 빠른 레시피 추천 (Phase 1.1) ──────────────────────────────
          _ComingSoonSection(
            emoji: '🍳',
            title: '빠른 레시피 추천',
            description: '보유 재료 기반으로 AI가 추천해 드려요.',
          ),

          const SizedBox(height: 20),

          // ─── 콘텐츠 (Phase 2.6) ────────────────────────────────────────
          _ComingSoonSection(
            emoji: '📰',
            title: '콘텐츠',
            description: '요리 과학, 식재료 보관 팁 등 유용한 칼럼.',
          ),
        ],
      ),
    );
  }
}

/// "후속 개발중" 표시가 있는 섹션 카드.
class _ComingSoonSection extends StatelessWidget {
  const _ComingSoonSection({
    required this.emoji,
    required this.title,
    required this.description,
  });

  final String emoji;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.showComingSoon(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '개발중 🚧',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
