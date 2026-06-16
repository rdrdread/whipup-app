import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/views/auth/login_screen.dart';
import 'package:whipup/views/camera/camera_screen.dart';
import 'package:whipup/views/column/column_browse_screen.dart';
import 'package:whipup/views/column/column_detail_screen.dart';
import 'package:whipup/views/column/column_screen.dart';
import 'package:whipup/views/home/home_screen.dart';
import 'package:whipup/views/household/household_screen.dart';
import 'package:whipup/views/my/my_screen.dart';
import 'package:whipup/views/onboarding/onboarding_screen.dart';
import 'package:whipup/views/onboarding/storage_setup_screen.dart';
import 'package:whipup/views/settings/settings_screen.dart';
import 'package:whipup/views/splash/splash_screen.dart';
import 'package:whipup/views/recipe/favorite_recipes_screen.dart';
import 'package:whipup/views/recipe/quick_recipe_screen.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/views/recipe/recipe_detail_screen.dart';
import 'package:whipup/views/recipe/recipe_edit_screen.dart';
import 'package:whipup/views/recipe/recipe_review_screen.dart';
import 'package:whipup/views/recipe/recipe_screen.dart';
import 'package:whipup/views/recipe/time_based_recipe_screen.dart';
import 'package:whipup/views/my/cooking_history_screen.dart';
import 'package:whipup/views/reward/reward_screen.dart';
import 'package:whipup/views/stock/stock_add_screen.dart';
import 'package:whipup/views/stock/stock_screen.dart';
import 'package:whipup/views/voice/voice_screen.dart';

// ─── 전환 헬퍼 ───────────────────────────────────────────────────────────────

/// 빠른 페이드 전환 (120ms) — push 화면용.
Page<void> _fadePage(GoRouterState state, Widget child) => CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 120),
      reverseTransitionDuration: const Duration(milliseconds: 100),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );

/// 전환 없음 — 탭 전환용.
Page<void> _noTransition(GoRouterState state, Widget child) =>
    NoTransitionPage(key: state.pageKey, child: child);

// ─── 라우터 ──────────────────────────────────────────────────────────────────

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
      pageBuilder: (_, state) => _noTransition(state, const SplashScreen()),
    ),

    // ─── 로그인 (Shell 밖) ───────────────────────────────────────────────
    GoRoute(
      path: '/login',
      pageBuilder: (_, state) => _fadePage(state, const LoginScreen()),
    ),

    // ─── 온보딩 (Shell 밖) ───────────────────────────────────────────────
    GoRoute(
      path: '/onboarding',
      pageBuilder: (_, state) => _fadePage(state, const OnboardingScreen()),
    ),
    GoRoute(
      path: '/storage-setup',
      pageBuilder: (_, state) => _fadePage(state, const StorageSetupScreen()),
    ),

    // ─── Shell (BottomNavigation) ────────────────────────────────────────
    ShellRoute(
      pageBuilder: (_, state, child) =>
          _noTransition(state, _MainShell(child: child)),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (_, state) => _noTransition(state, const HomeScreen()),
        ),
        GoRoute(
          path: '/stock',
          pageBuilder: (_, state) {
            final expiry = state.uri.queryParameters['expiry'] == 'true';
            return _noTransition(state, StockScreen(initialExpiry: expiry));
          },
        ),
        GoRoute(
          path: '/recipe',
          pageBuilder: (_, state) =>
              _noTransition(state, const RecipeScreen()),
        ),
        GoRoute(
          path: '/my',
          pageBuilder: (_, state) => _noTransition(state, const MyScreen()),
        ),
      ],
    ),

    // ─── 재고 관련 ───────────────────────────────────────────────────────
    GoRoute(
      path: '/stock/add',
      pageBuilder: (_, state) {
        final location = state.uri.queryParameters['location'];
        final containerIndex =
            int.tryParse(state.uri.queryParameters['containerIndex'] ?? '0') ??
                0;
        final categoryName = state.uri.queryParameters['category'];
        return _fadePage(
          state,
          StockAddScreen(
            initialStorageLocationName: location,
            initialContainerIndex: containerIndex,
            initialCategoryName: categoryName,
          ),
        );
      },
    ),
    GoRoute(
      path: '/stock/edit/:id',
      pageBuilder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return _fadePage(state, StockAddScreen(itemId: id));
      },
    ),

    // ─── 레시피 관련 (구체적 경로 먼저, :id 파라미터 마지막) ───────────────────
    GoRoute(
      path: '/recipe/favorites',
      pageBuilder: (_, state) =>
          _fadePage(state, const FavoriteRecipesScreen()),
    ),
    GoRoute(
      path: '/recipe/review',
      pageBuilder: (_, state) {
        final title = state.extra as String? ?? '요리';
        return _fadePage(state, RecipeReviewScreen(recipeTitle: title));
      },
    ),

    // ─── 빠른 레시피 (요리명 기반 AI 생성) ──────────────────────────────────
    GoRoute(
      path: '/recipe/quick',
      pageBuilder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return _fadePage(
          state,
          QuickRecipeScreen(
            dishName: extra['name'] as String? ?? '레시피',
            emoji: extra['emoji'] as String? ?? '🍽️',
          ),
        );
      },
    ),

    // ─── 시간대별 추천 레시피 ────────────────────────────────────────────────
    GoRoute(
      path: '/recipe/time',
      pageBuilder: (_, state) {
        final period = state.uri.queryParameters['period'] ?? 'dinner';
        return _fadePage(state, TimeBasedRecipeScreen(period: period));
      },
    ),

    // ─── 레시피 편집 ─────────────────────────────────────────────────────────
    GoRoute(
      path: '/recipe/:id/edit',
      pageBuilder: (_, state) {
        final recipe = state.extra as Recipe?;
        if (recipe == null) return _fadePage(state, const SizedBox.shrink());
        return _fadePage(state, RecipeEditScreen(recipe: recipe));
      },
    ),

    // ─── 레시피 상세 (파라미터 경로는 구체적 경로 뒤에 위치) ────────────────────
    GoRoute(
      path: '/recipe/:id',
      pageBuilder: (_, state) {
        final id = state.pathParameters['id'] ?? '';
        final recipe = state.extra is Recipe ? state.extra as Recipe : null;
        return _fadePage(
            state, RecipeDetailScreen(recipeId: id, initialRecipe: recipe));
      },
    ),

    // ─── 카메라 OCR (Phase 1.2) ──────────────────────────────────────────
    GoRoute(
      path: '/camera',
      pageBuilder: (_, state) => _fadePage(state, const CameraScreen()),
    ),

    // ─── 음성 입력 (Phase 1.3) ───────────────────────────────────────────
    GoRoute(
      path: '/voice',
      pageBuilder: (_, state) => _fadePage(state, const VoiceScreen()),
    ),

    // ─── 마이 하위 화면 ──────────────────────────────────────────────────
    GoRoute(
      path: '/my/cooking-history',
      pageBuilder: (_, state) =>
          _fadePage(state, const CookingHistoryScreen()),
    ),
    GoRoute(
      path: '/my/reward',
      pageBuilder: (_, state) => _fadePage(state, const RewardScreen()),
    ),
    GoRoute(
      path: '/my/settings',
      pageBuilder: (_, state) => _fadePage(state, const SettingsScreen()),
    ),
    GoRoute(
      path: '/household',
      pageBuilder: (_, state) => _fadePage(state, const HouseholdScreen()),
    ),
    GoRoute(
      path: '/my/column',
      pageBuilder: (_, state) => _fadePage(state, const ColumnScreen()),
    ),
    GoRoute(
      path: '/my/column/:id',
      pageBuilder: (_, state) => _fadePage(
          state, ColumnDetailScreen(columnId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/columns',
      pageBuilder: (_, state) => _fadePage(state, const ColumnBrowseScreen()),
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

