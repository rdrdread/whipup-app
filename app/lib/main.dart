import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whipup/providers/app_settings_providers.dart';
import 'package:whipup/router/app_router.dart';
import 'package:whipup/theme/app_theme.dart';

// ─── Entry Point ──────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(
    const ProviderScope(
      child: WhipUpApp(),
    ),
  );
}

// ─── Root App ─────────────────────────────────────────────────────────────────

/// WhipUp 앱의 루트 위젯.
///
/// [ProviderScope]를 통해 Riverpod 상태를 주입하며,
/// [GoRouter]를 사용한 선언적 라우팅을 구성한다.
/// [ThemeModeNotifier]를 통해 테마 모드를 동적으로 제어한다.
class WhipUpApp extends ConsumerWidget {
  const WhipUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeNotifierProvider);
    final themeMode = themeModeAsync.asData?.value ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'WhipUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
