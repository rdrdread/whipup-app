import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/providers/stock_providers.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';

/// 홈 화면 (대시보드).
///
/// - 대시보드 카드: 전체 재고 현황 + 유통기한 임박
/// - 빠른 레시피 추천: 가로 슬라이더
/// - 콘텐츠(칼럼): 가로 슬라이더
///
/// 레이아웃: `docs/core/screen_layout.md §3.1`
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(stockSummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAF8),
        elevation: 0,
        title: const Text(
          'WhipUp',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: AppTheme.primaryColor,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: '알림',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/my/settings'),
            tooltip: '설정',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // ─── 대시보드 카드 ─────────────────────────────────────────────
          summaryAsync.when(
            data: (summary) => _DashboardCard(summary: summary),
            loading: () => const _DashboardCard(summary: null),
            error: (_, __) => const _DashboardCard(summary: null),
          ),

          const SizedBox(height: 4),

          // ─── 빠른 레시피 추천 ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: GestureDetector(
              onTap: () => context.go('/recipe'),
              child: const Row(
                children: [
                  const TwemojiIcon('🍳', size: 18),
                  SizedBox(width: 6),
                  Text(
                    '빠른 레시피 추천',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              children: [
                _RecipeSlideCard(
                  emoji: '🫕',
                  badge: 'SOUP',
                  badgeColor: const Color(0xFF1565C0),
                  badgeBg: const Color(0xFFE3F2FD),
                  title: '소고기 배추 전골',
                  meta: '30분 · 보통',
                  onTap: () => context.go('/recipe'),
                ),
                const SizedBox(width: 10),
                _RecipeSlideCard(
                  emoji: '🥘',
                  badge: 'MAIN',
                  badgeColor: const Color(0xFF2E7D32),
                  badgeBg: const Color(0xFFE8F5E9),
                  title: '소불고기 배추쌈',
                  meta: '25분 · 쉬움',
                  onTap: () => context.go('/recipe'),
                ),
                const SizedBox(width: 10),
                _RecipeSlideCard(
                  emoji: '🍲',
                  badge: 'SOUP',
                  badgeColor: const Color(0xFF1565C0),
                  badgeBg: const Color(0xFFE3F2FD),
                  title: '배추된장국',
                  meta: '20분 · 쉬움',
                  onTap: () => context.go('/recipe'),
                ),
              ],
            ),
          ),

          // ─── 콘텐츠 ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: const Row(
              children: [
                const TwemojiIcon('📰', size: 18),
                SizedBox(width: 6),
                Text(
                  '콘텐츠',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 108,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              children: const [
                _ContentCard(
                  badge: '요리 과학',
                  badgeColor: Color(0xFF42A5F5),
                  badgeBg: Color(0x1A42A5F5),
                  title: '당근은 왜 기름과 함께?',
                  subtitle: '지용성 비타민의 비밀을 알면 당근 요리가 달라져요',
                ),
                SizedBox(width: 10),
                _ContentCard(
                  badge: '재료 보관',
                  badgeColor: Color(0xFFEF5350),
                  badgeBg: Color(0x1AEF5350),
                  title: '실온 해동 vs 냉장 해동',
                  subtitle: '정답은 의외로 간단해요. 안전한 해동법을 알아볼까요',
                ),
                SizedBox(width: 10),
                _ContentCard(
                  badge: '홈 가드닝',
                  badgeColor: Color(0xFFF57F17),
                  badgeBg: Color(0x1AF57F17),
                  title: '베란다 허브 키우기',
                  subtitle: '파슬리부터 시작하면 요리가 더 즐거워져요',
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── 대시보드 카드 ─────────────────────────────────────────────────────────────

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({this.summary});

  final StockSummary? summary;

  @override
  Widget build(BuildContext context) {
    final total = summary?.totalCount ?? 0;
    final expiring = summary?.expiringCount ?? 0;

    return GestureDetector(
      onTap: () => context.go('/stock'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, Color(0xFFE07A4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x35F04E23),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 헤더: 라벨 + 전체 개수 ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    '오늘의 냉장고',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      '개',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ─── 보관 위치별 박스 4개 ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _LocationBox(
                    emoji: '🧊',
                    label: '냉장',
                    count: summary?.fridgeCount ?? 0,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _LocationBox(
                    emoji: '❄️',
                    label: '냉동',
                    count: summary?.freezerCount ?? 0,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _LocationBox(
                    emoji: '📦',
                    label: '팬트리',
                    count: summary?.pantryCount ?? 0,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _LocationBox(
                    emoji: '🧂',
                    label: '서랍',
                    count: summary?.drawerCount ?? 0,
                  ),
                ),
              ],
            ),

            // ─── 유통기한 상태 + 재료 추가 버튼 ─────────────────────────
            const Divider(color: Colors.white24, height: 20),
            Row(
              children: [
                if (expiring > 0) ...[
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 15,
                    color: Color(0xFFFFE082),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '유통기한 임박 $expiring개 있어요',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 15,
                    color: Colors.white60,
                  ),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text(
                      '모든 재료 신선해요 ✨',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
                GestureDetector(
                  onTap: () => context.push('/stock/add'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 3),
                        Text(
                          '재료 추가',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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

class _LocationBox extends StatelessWidget {
  const _LocationBox({
    required this.emoji,
    required this.label,
    required this.count,
  });

  final String emoji;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TwemojiIcon(emoji, size: 18),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 10,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── 레시피 슬라이더 카드 ───────────────────────────────────────────────────────

class _RecipeSlideCard extends StatelessWidget {
  const _RecipeSlideCard({
    required this.emoji,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
    required this.title,
    required this.meta,
    required this.onTap,
  });

  final String emoji;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;
  final String title;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            TwemojiIcon(emoji, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '🕐 $meta',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: Color(0x992C2C2C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 콘텐츠 카드 ───────────────────────────────────────────────────────────────

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
    required this.title,
    required this.subtitle,
  });

  final String badge;
  final Color badgeColor;
  final Color badgeBg;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                color: Color(0x992C2C2C),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
