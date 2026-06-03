import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/views/camera/camera_screen.dart';
import 'package:whipup/views/column/column_browse_screen.dart';
import 'package:whipup/views/column/column_detail_screen.dart';
import 'package:whipup/views/column/column_screen.dart';
import 'package:whipup/views/home/home_screen.dart';
import 'package:whipup/views/my/my_screen.dart';
import 'package:whipup/views/onboarding/onboarding_screen.dart';
import 'package:whipup/views/onboarding/storage_setup_screen.dart';
import 'package:whipup/views/settings/settings_screen.dart';
import 'package:whipup/views/splash/splash_screen.dart';
import 'package:whipup/views/recipe/quick_recipe_screen.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/views/recipe/recipe_detail_screen.dart';
import 'package:whipup/views/recipe/recipe_review_screen.dart';
import 'package:whipup/views/recipe/recipe_screen.dart';
import 'package:whipup/views/recipe/time_based_recipe_screen.dart';
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
        final categoryName = state.uri.queryParameters['category'];
        return StockAddScreen(
          initialStorageLocationName: location,
          initialContainerIndex: containerIndex,
          initialCategoryName: categoryName,
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
        // extra로 Recipe 객체가 전달되면 Isar 조회 없이 직접 렌더링
        final recipe = state.extra is Recipe ? state.extra as Recipe : null;
        return RecipeDetailScreen(recipeId: id, initialRecipe: recipe);
      },
    ),
    GoRoute(
      path: '/recipe/favorites',
      builder: (context, state) => const RecipeScreen(),
    ),
    GoRoute(
      path: '/recipe/review',
      builder: (context, state) {
        final title = state.extra as String? ?? '요리';
        return RecipeReviewScreen(recipeTitle: title);
      },
    ),

    // ─── 빠른 레시피 (요리명 기반 AI 생성) ──────────────────────────────────
    GoRoute(
      path: '/recipe/quick',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return QuickRecipeScreen(
          dishName: extra['name'] as String? ?? '레시피',
          emoji: extra['emoji'] as String? ?? '🍽️',
        );
      },
    ),

    // ─── 시간대별 추천 레시피 ────────────────────────────────────────────────
    GoRoute(
      path: '/recipe/time',
      builder: (context, state) {
        final period = state.uri.queryParameters['period'] ?? 'dinner';
        return TimeBasedRecipeScreen(period: period);
      },
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
    GoRoute(
      path: '/columns',
      builder: (context, state) => const ColumnBrowseScreen(),
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
          backgroundColor: AppTheme.backgroundColor,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_basket_outlined),
              selectedIcon: Icon(Icons.shopping_basket),
              label: '재고',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: '레시피',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle),
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

