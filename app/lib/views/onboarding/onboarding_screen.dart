import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/theme/app_theme.dart';

/// 온보딩 완료 플래그 저장 키.
const _kOnboardingDoneKey = 'onboarding_done';

/// 온보딩 화면 (3단계).
///
/// 앱 최초 실행 시 표시되며, 완료 또는 건너뛰기 시
/// [FlutterSecureStorage]에 완료 여부를 저장하고 홈 화면으로 이동한다.
///
/// 디자인: `docs/core/screen_layout.md §1` — onboarding
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      emoji: '🧊',
      title: '냉장고 속 재료를\n한눈에 관리해요',
      subtitle: '유통기한 임박 재료를 놓치지 않고\n효율적으로 재고를 관리하세요',
    ),
    _OnboardingPage(
      emoji: '🍳',
      title: '재료에서 레시피로\n뚝딱 변신!',
      subtitle: '보유한 재료를 선택하면 AI가\n맞춤 레시피를 추천해 드려요',
    ),
    _OnboardingPage(
      emoji: '🏆',
      title: '요리할수록\n쌓이는 나만의 기록',
      subtitle: '업적을 달성하며 요리 습관을 만들고\n즐거운 부엌 생활을 시작하세요',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await const FlutterSecureStorage().write(
      key: _kOnboardingDoneKey,
      value: 'true',
    );
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    context.go('/home');
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── 건너뛰기 버튼 ──────────────────────────────────────────
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: isLastPage
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: _finishOnboarding,
                        child: const Text(
                          '건너뛰기',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            color: Color(0x992C2C2C),
                          ),
                        ),
                      ),
              ),
            ),

            // ─── 페이지뷰 ───────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (_, index) => _pages[index],
              ),
            ),

            const SizedBox(height: 24),

            // ─── 도트 인디케이터 ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primaryColor
                        : const Color(0x332C2C2C),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ─── 다음 / 시작하기 버튼 ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isLastPage ? '시작하기 🍳' : '다음',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 온보딩 페이지 ──────────────────────────────────────────────────────────────

/// 개별 온보딩 페이지 위젯.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ─── 이모지 아이콘 ──────────────────────────────────────────
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 64),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // ─── 제목 ───────────────────────────────────────────────────
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),

          // ─── 부제목 ─────────────────────────────────────────────────
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: Color(0x992C2C2C),
            ),
          ),
        ],
      ),
    );
  }
}
