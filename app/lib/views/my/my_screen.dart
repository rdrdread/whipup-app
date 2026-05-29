import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/providers/reward_providers.dart';
import 'package:whipup/theme/app_theme.dart';

/// 마이페이지 화면.
///
/// - 활동 통계 그리드 (총요리/등록재료/시도종류)
/// - 메뉴: 나의기록 / 칼럼 / 설정
///
/// 레이아웃: `docs/core/screen_layout.md §2.1`
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(rewardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        title: const Text(
          '마이',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/my/settings'),
            tooltip: '설정',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ─── 통계 그리드 ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: statsAsync.when(
              data: (stats) => Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      value: '${stats.totalRecipesCompleted}',
                      label: '총 요리',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      value: '${stats.totalStocksAdded}',
                      label: '등록 재료',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      value: '${stats.uniqueRecipeTypeCount}',
                      label: '시도 종류',
                    ),
                  ),
                ],
              ),
              loading: () => Row(
                children: [
                  Expanded(child: _StatBox(value: '—', label: '총 요리')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatBox(value: '—', label: '등록 재료')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatBox(value: '—', label: '시도 종류')),
                ],
              ),
              error: (_, _e) => const SizedBox.shrink(),
            ),
          ),

          // ─── 메뉴 카드 ────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _MenuRow(
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppTheme.primaryColor,
                  label: '나의 기록',
                  onTap: () => context.push('/my/reward'),
                ),
                const Divider(height: 1, thickness: 1, indent: 16),
                _MenuRow(
                  icon: Icons.auto_stories_rounded,
                  iconColor: AppTheme.primaryColor,
                  label: '칼럼',
                  onTap: () => context.push('/my/column'),
                ),
                const Divider(height: 1, thickness: 1, indent: 16),
                _MenuRow(
                  icon: Icons.settings_rounded,
                  iconColor: const Color(0x992C2C2C),
                  label: '설정',
                  onTap: () => context.push('/my/settings'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── 기타 메뉴 (카메라/음성 입력) ─────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _MenuRow(
                  icon: Icons.camera_alt_rounded,
                  iconColor: const Color(0x992C2C2C),
                  label: '영수증 스캔',
                  subtitle: '영수증 촬영으로 재료 추가',
                  onTap: () => context.push('/camera'),
                ),
                const Divider(height: 1, thickness: 1, indent: 16),
                _MenuRow(
                  icon: Icons.mic_rounded,
                  iconColor: const Color(0x992C2C2C),
                  label: '음성 재료 입력',
                  subtitle: '말로 재료를 추가해요',
                  onTap: () => context.push('/voice'),
                ),
                const Divider(height: 1, thickness: 1, indent: 16),
                _MenuRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0x992C2C2C),
                  label: '앱 정보',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
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

// ─── 통계 박스 ─────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              color: Color(0x992C2C2C),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── 메뉴 행 ─────────────────────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: Color(0x992C2C2C),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0x992C2C2C),
            ),
          ],
        ),
      ),
    );
  }
}
