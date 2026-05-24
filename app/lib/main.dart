import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/theme/app_theme.dart';

// ─── Router ───────────────────────────────────────────────────────────────────

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _PlaceholderHomePage(),
    ),
  ],
);

// ─── Entry Point ──────────────────────────────────────────────────────────────

void main() {
  runApp(
    const ProviderScope(
      child: WhipUpApp(),
    ),
  );
}

// ─── Root App ─────────────────────────────────────────────────────────────────

/// WhipUp 앱의 루트 위젯.
/// [ProviderScope] 하위에서 라우팅과 테마를 초기화한다.
class WhipUpApp extends StatelessWidget {
  const WhipUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WhipUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

// ─── Placeholder ──────────────────────────────────────────────────────────────

class _PlaceholderHomePage extends StatelessWidget {
  const _PlaceholderHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhipUp 🍳'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🥬',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 16),
            Text(
              '냉장고 속 재료로 뚝딱!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Initial Setup Complete ✅',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
