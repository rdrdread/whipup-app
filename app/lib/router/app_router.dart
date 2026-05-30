import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/views/camera/camera_screen.dart';
import 'package:whipup/views/column/column_screen.dart';
import 'package:whipup/views/column/column_detail_screen.dart';
import 'package:whipup/views/home/home_screen.dart';
import 'package:whipup/views/my/my_screen.dart';
import 'package:whipup/views/onboarding/onboarding_screen.dart';
import 'package:whipup/views/onboarding/storage_setup_screen.dart';
import 'package:whipup/views/settings/settings_screen.dart';
import 'package:whipup/views/splash/splash_screen.dart';
import 'package:whipup/views/recipe/recipe_detail_screen.dart';
import 'package:whipup/views/recipe/recipe_screen.dart';
import 'package:whipup/views/reward/reward_screen.dart';
import 'package:whipup/views/stock/stock_add_screen.dart';
import 'package:whipup/views/stock/stock_screen.dart';
import 'package:whipup/views/voice/voice_screen.dart';

/// WhipUp 앱 라우터.
///
/// ShellRoute로 BottomNavigation Shell을 감싸고, 전체 화면(재료 추가/수정)은
/// Shell 외부에 배치한다.
///
/// 라우트 구조: `docs/core/screen_layout.md §1`
final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // ─── 스플래시 (Shell 밖) ──────────────────────────────────────────────
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // ─── 온보딩 (Shell 밖) ───────────────────────────────────────────────
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/storage-setup',
      builder: (context, state) => const StorageSetupScreen(),
    ),

    // ─── Shell (BottomNavigation) ────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => _MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/stock',
          builder: (context, state) => const StockScreen(),
        ),
        GoRoute(
          path: '/recipe',
          builder: (context, state) => const RecipeScreen(),
        ),
        GoRoute(
          path: '/my',
          builder: (context, state) => const MyScreen(),
        ),
      ],
    ),

    // ─── 재고 관련 ───────────────────────────────────────────────────────
    GoRoute(
      path: '/stock/add',
      builder: (context, state) {
        final location = state.uri.queryParameters['location'];
        final containerIndex =
            int.tryParse(state.uri.queryParameters['containerIndex'] ?? '0') ?? 0;
        return StockAddScreen(
          initialStorageLocationName: location,
          initialContainerIndex: containerIndex,
        );
      },
    ),
    GoRoute(
      path: '/stock/edit/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return StockAddScreen(itemId: id);
      },
    ),

    // ─── 레시피 관련 (Phase 1.1) ─────────────────────────────────────────
    GoRoute(
      path: '/recipe/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return RecipeDetailScreen(recipeId: id);
      },
    ),
    GoRoute(
      path: '/recipe/favorites',
      builder: (context, state) => const RecipeScreen(),
    ),

    // ─── 카메라 OCR (Phase 1.2) ──────────────────────────────────────────
    GoRoute(
      path: '/camera',
      builder: (context, state) => const CameraScreen(),
    ),

    // ─── 음성 입력 (Phase 1.3) ───────────────────────────────────────────
    GoRoute(
      path: '/voice',
      builder: (context, state) => const VoiceScreen(),
    ),

    // ─── 마이 하위 화면 ──────────────────────────────────────────────────
    GoRoute(
      path: '/my/reward',
      builder: (context, state) => const RewardScreen(),
    ),
    GoRoute(
      path: '/my/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/my/column',
      builder: (context, state) => const ColumnScreen(),
    ),
    GoRoute(
      path: '/my/column/:id',
      builder: (context, state) =>
          ColumnDetailScreen(columnId: state.pathParameters['id']!),
    ),
  ],
);

// ─── Main Shell ───────────────────────────────────────────────────────────────

/// 바텀 네비게이션이 포함된 메인 쉘.
class _MainShell extends StatefulWidget {
  const _MainShell({required this.child});
  final Widget child;

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  Future<void> _showExitDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '앱을 종료할까요?',
          style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          '지금 종료하면 WhipUp을 닫아요.',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(fontFamily: 'Pretendard')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '종료',
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: Theme.of(ctx).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _locationToIndex(location),
          onDestinationSelected: (index) => _onTabTapped(context, index),
          animationDuration: const Duration(milliseconds: 200),
          backgroundColor: const Color(0xFFFAFAF8),
          surfaceTintColor: Colors.transparent,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.cottage_outlined),
              selectedIcon: Icon(Icons.cottage),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.kitchen_outlined),
              selectedIcon: Icon(Icons.kitchen),
              label: '재고',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: '레시피',
            ),
            NavigationDestination(
              icon: Icon(Icons.face_outlined),
              selectedIcon: Icon(Icons.face),
              label: '마이',
            ),
          ],
        ),
      ),
    );
  }

  int _locationToIndex(String location) {
    if (location.startsWith('/stock')) return 1;
    if (location.startsWith('/recipe')) return 2;
    if (location.startsWith('/my')) return 3;
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/stock');
      case 2:
        context.go('/recipe');
      case 3:
        context.go('/my');
    }
  }
}

