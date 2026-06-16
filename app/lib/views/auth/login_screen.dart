import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/providers/auth_providers.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';

/// 구글 계정 로그인 화면.
///
/// 앱 최초 진입 또는 로그아웃 후 표시된다.
/// 로그인 성공 시 온보딩 완료 여부에 따라 /onboarding 또는 /home으로 이동한다.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _loading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();

      if (user == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      if (!mounted) return;
      final done = await _storage.read(key: 'onboarding_done');
      if (!mounted) return;

      // ignore: use_build_context_synchronously
      context.go(done == 'true' ? '/home' : '/onboarding');
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = '로그인에 실패했어요. 다시 시도해 주세요.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ─── 앱 로고 ────────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.flameOrange,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.flameOrange.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(child: TwemojiIcon('🍳', size: 44)),
              ),

              const SizedBox(height: 24),

              Text(
                'WhipUp',
                style: tt.headlineMedium?.copyWith(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '냉장고 재료로 근사한 한 끼를\n뚝딱 만들어 드릴게요 🧑‍🍳',
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // ─── 가구 공유 안내 칩 ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TwemojiIcon('🏠', size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '가족과 재고를 함께 관리할 수 있어요',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ─── Google 로그인 버튼 ───────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : OutlinedButton.icon(
                        onPressed: _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: cs.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Image.asset(
                          'assets/images/google_logo.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.g_mobiledata_rounded,
                            size: 24,
                          ),
                        ),
                        label: Text(
                          'Google 계정으로 시작하기',
                          style: tt.labelLarge?.copyWith(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: tt.bodySmall?.copyWith(color: cs.error),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 16),

              Text(
                '로그인 시 재고·레시피 데이터가 안전하게 보호됩니다.',
                textAlign: TextAlign.center,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
