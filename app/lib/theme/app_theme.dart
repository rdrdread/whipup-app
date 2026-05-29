import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// WhipUp 앱 테마.
///
/// Flame Orange (#F04E23)를 Primary 색상으로 사용한다.
/// 디자인 토큰: `docs/core/design_system.md`, `docs/brand-assets/README.md`
abstract final class AppTheme {
  // ─── 색상 토큰 ─────────────────────────────────────────────────────────────

  /// Primary: Flame Orange
  static const Color primaryColor = Color(0xFFF04E23);

  /// Primary Container
  static const Color primaryContainerColor = Color(0xFFFDD0C0);

  /// Dark Mode Primary (밝게 조정)
  static const Color primaryDarkColor = Color(0xFFF47A5C);

  /// 유통기한 fresh 색상
  static const Color freshGreen = Color(0xFF4CAF50);

  /// 유통기한 warning 색상
  static const Color warningAmber = Color(0xFFFFC107);

  /// 유통기한 danger 색상
  static const Color dangerRed = Color(0xFFF44336);

  // ─── 테마 ─────────────────────────────────────────────────────────────────

  /// 라이트 테마.
  static ThemeData get light => FlexThemeData.light(
        colors: const FlexSchemeColor(
          primary: primaryColor,
          primaryContainer: primaryContainerColor,
          secondary: Color(0xFFFF7043),
          secondaryContainer: Color(0xFFFFCCBC),
          tertiary: Color(0xFF795548),
          tertiaryContainer: Color(0xFFD7CCC8),
          appBarColor: primaryColor,
          error: dangerRed,
        ),
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
          // 카드
          cardRadius: 16.0,
          // 버튼
          elevatedButtonRadius: 12.0,
          filledButtonRadius: 12.0,
          outlinedButtonRadius: 12.0,
          textButtonRadius: 8.0,
          // FAB
          fabRadius: 16.0,
          // 칩
          chipRadius: 8.0,
          // 입력 필드
          inputDecoratorRadius: 12.0,
          inputDecoratorIsFilled: true,
          // 다이얼로그
          dialogRadius: 20.0,
          // BottomSheet
          bottomSheetRadius: 20.0,
          // SnackBar
          snackBarRadius: 8,
          // NavigationBar
          navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          navigationBarSelectedIconSchemeColor: SchemeColor.primary,
          navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
          navigationBarBackgroundSchemeColor: SchemeColor.surface,
          navigationBarElevation: 0,
          // TabBar
          tabBarIndicatorSchemeColor: SchemeColor.primary,
          tabBarItemSchemeColor: SchemeColor.primary,
          tabBarUnselectedItemSchemeColor: SchemeColor.onSurfaceVariant,
        ),
        keyColors: const FlexKeyColors(
          useSecondary: true,
          useTertiary: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ).copyWith(
        // ─── 텍스트 스타일 오버라이드 ────────────────────────────────────────
        scaffoldBackgroundColor: const Color(0xFFFAFAF8),
        textTheme: _buildTextTheme(Brightness.light),
      );

  /// 다크 테마.
  static ThemeData get dark => FlexThemeData.dark(
        colors: const FlexSchemeColor(
          primary: primaryDarkColor,
          primaryContainer: Color(0xFF7A2210),
          secondary: Color(0xFFFF8A65),
          secondaryContainer: Color(0xFF4E2118),
          tertiary: Color(0xFFBCAAA4),
          tertiaryContainer: Color(0xFF4E342E),
          appBarColor: Color(0xFF1A0F0C),
          error: Color(0xFFEF9A9A),
        ),
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 13,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
          cardRadius: 16.0,
          elevatedButtonRadius: 12.0,
          filledButtonRadius: 12.0,
          outlinedButtonRadius: 12.0,
          textButtonRadius: 8.0,
          fabRadius: 16.0,
          chipRadius: 8.0,
          inputDecoratorRadius: 12.0,
          inputDecoratorIsFilled: true,
          dialogRadius: 20.0,
          bottomSheetRadius: 20.0,
          snackBarRadius: 8,
          navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          navigationBarSelectedIconSchemeColor: SchemeColor.primary,
          navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
          navigationBarBackgroundSchemeColor: SchemeColor.surface,
          navigationBarElevation: 0,
          tabBarIndicatorSchemeColor: SchemeColor.primary,
          tabBarItemSchemeColor: SchemeColor.primary,
          tabBarUnselectedItemSchemeColor: SchemeColor.onSurfaceVariant,
        ),
        keyColors: const FlexKeyColors(
          useSecondary: true,
          useTertiary: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ).copyWith(
        textTheme: _buildTextTheme(Brightness.dark),
      );

  // ─── 헬퍼 ─────────────────────────────────────────────────────────────────

  /// Pretendard 기반 텍스트 테마를 빌드한다.
  /// 타입 스케일: `docs/core/design_system.md §3`
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF5F5F5);
    final subtleColor = brightness == Brightness.light
        ? const Color(0xFF666666)
        : const Color(0xFFAAAAAA);

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w900,
        fontSize: 57,
        color: baseColor,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w800,
        fontSize: 45,
        color: baseColor,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 36,
        color: baseColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w900,
        fontSize: 32,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w800,
        fontSize: 28,
        color: baseColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: baseColor,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
        fontSize: 12,
        color: subtleColor,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: baseColor,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w500,
        fontSize: 12,
        color: subtleColor,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w500,
        fontSize: 11,
        color: subtleColor,
      ),
    );
  }
}
