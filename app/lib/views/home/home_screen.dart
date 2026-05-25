import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/providers/stock_providers.dart';
import 'package:whipup/theme/app_theme.dart';

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
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        title: const Text(
          'WhipUp',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppTheme.primaryColor,
            letterSpacing: -0.25,
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
                  Text('🍳', style: TextStyle(fontSize: 18)),
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
            height: 100,
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
                Text('📰', style: TextStyle(fontSize: 18)),
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFFE88A5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40F04E23),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 제목 + 숫자 ─────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '보유 재료',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '우리집 냉장고 현황',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$total',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),

          // ─── 위치별 분류 ────────────────────────────────────────────
          const SizedBox(height: 12),
          Row(
            children: [
              _LocationChip(
                emoji: '🧊',
                label: '냉장 ${summary?.fridgeCount ?? 0}',
              ),
              const SizedBox(width: 12),
              _LocationChip(
                emoji: '❄️',
                label: '냉동 ${summary?.freezerCount ?? 0}',
              ),
              const SizedBox(width: 12),
              _LocationChip(
                emoji: '📦',
                label: '팬트리 ${summary?.pantryCount ?? 0}',
              ),
              const SizedBox(width: 12),
              _LocationChip(
                emoji: '🧂',
                label: '서랍 ${summary?.drawerCount ?? 0}',
              ),
            ],
          ),

          // ─── 유통기한 임박 경고 ─────────────────────────────────────
          if (expiring > 0) ...[
            const Divider(
              color: Colors.white24,
              height: 20,
            ),
            Row(
              children: [
                const Icon(
                  Icons.warning_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  '유통기한 임박 ',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$expiring개',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
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
            Text(emoji, style: const TextStyle(fontSize: 36)),
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
