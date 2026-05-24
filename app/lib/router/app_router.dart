import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/views/home/home_screen.dart';
import 'package:whipup/views/my/my_screen.dart';
import 'package:whipup/views/recipe/recipe_screen.dart';
import 'package:whipup/views/stock/stock_add_screen.dart';
import 'package:whipup/views/stock/stock_screen.dart';

/// WhipUp 앱 라우터.
///
/// ShellRoute로 BottomNavigation Shell을 감싸고, 전체 화면(재료 추가/수정)은
/// Shell 외부에 배치한다.
///
/// 라우트 구조: `docs/core/screen_layout.md §1`
final appRouter = GoRouter(
  initialLocation: '/stock',
  routes: [
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

    // ─── 전체 화면 (Shell 외부) ───────────────────────────────────────────
    GoRoute(
      path: '/stock/add',
      builder: (context, state) {
        final location = state.uri.queryParameters['location'];
        return StockAddScreen(
          initialStorageLocationName: location,
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
  ],
);

// ─── Main Shell ───────────────────────────────────────────────────────────────

/// 바텀 네비게이션이 포함된 메인 쉘.
class _MainShell extends StatelessWidget {
  const _MainShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _locationToIndex(location),
        onDestinationSelected: (index) => _onTabTapped(context, index),
        animationDuration: const Duration(milliseconds: 200),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen_rounded),
            label: '재고',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu_rounded),
            label: '레시피',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: '마이',
          ),
        ],
      ),
    );
  }

  int _locationToIndex(String location) {
    if (location.startsWith('/stock')) return 1;
    if (location.startsWith('/recipe')) return 2;
    if (location.startsWith('/my')) return 3;
    return 0; // /home
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
