import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/theme/app_theme.dart';

/// 스플래시 화면.
///
/// 앱 최초 진입 시 2초간 표시 후 홈으로 자동 이동.
/// 디자인: `docs/core/screen_layout.md` — screens_r4 splash
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    // 2초 후 홈으로 이동
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ─── 아이콘 ───────────────────────────────────────────────
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4DF04E23),
                      blurRadius: 32,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🍳', style: TextStyle(fontSize: 48)),
                ),
              ),

              const SizedBox(height: 20),

              // ─── 앱 이름 ─────────────────────────────────────────────
              const Text(
                'WhipUp',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 6),

              // ─── 태그라인 ─────────────────────────────────────────────
              const Text(
                '뚝딱, 근사한 한 끼',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0x992C2C2C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
