import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';

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

    // 2초 후 로그인 상태에 따라 라우팅
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;

      // Windows에서는 Firebase 미사용 — 바로 홈으로 이동
      if (Platform.isWindows) {
        context.go('/home');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // ignore: use_build_context_synchronously
        context.go('/login');
        return;
      }
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final done = await storage.read(key: 'onboarding_done');
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      context.go(done == 'true' ? '/home' : '/onboarding');
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
                  color: AppTheme.flameOrange,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.flameOrange.withAlpha(0x4D),
                      blurRadius: 32,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: TwemojiIcon('🍳', size: 48),
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
                  color: AppTheme.iconSubtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
