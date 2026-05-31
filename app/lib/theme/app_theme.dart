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

  /// Primary Container: Clean Off-White
  static const Color primaryContainerColor = Color(0xFFFAFAFA);

  /// Dark Mode Primary (라이트와 동일한 Flame Orange로 통일)
  static const Color primaryDarkColor = primaryColor;

  /// 배경색: Pure White
  static const Color backgroundColor = Color(0xFFFFFFFF);

  /// 유통기한 fresh 색상 (데모 r4 팔레트)
  static const Color freshGreen = Color(0xFF66BB6A);

  /// 유통기한 warning 색상 (브랜드 Warm Amber, 더 밝은 톤)
  static const Color warningAmber = Color(0xFFFFC107);

  /// 유통기한 danger 색상 (데모 r4 팔레트)
  static const Color dangerRed = Color(0xFFEF5350);

  // ─── 서피스 / 카드 ────────────────────────────────────────────────────────

  /// 카드·패널 공통 배경: Clean Off-White (surfaceContainerLow 대체)
  static const Color cardColor = Color(0xFFFAFAFA);

  /// 중간 강조 서피스: 연한 중립 회색 (surfaceContainerHigh 대체)
  static const Color surfaceHigh = Color(0xFFF0F0F0);

  /// 가장 강조된 서피스: 중립 회색 (surfaceContainerHighest 대체)
  static const Color surfaceHighest = Color(0xFFE8E8E8);

  /// 재고 삭제 스와이프 배경: dangerRed 10% 틴트
  static const Color dismissSurface = Color(0xFFFFEBEB);

  // ─── 아이콘 / 텍스트 보조 색상 ───────────────────────────────────────────

  /// 보조 아이콘·텍스트: 60% 불투명 다크 (비활성 탭, 부제목 등)
  static const Color iconSubtle = Color(0x992C2C2C);

  /// 중립 회색 아이콘: chevron, 힌트 등
  static const Color iconGrey = Color(0xFF999999);

  /// 진한 텍스트: near-black (강조 레이블)
  static const Color textDark = Color(0xFF2C2C2C);

  /// 비활성화 상태: 40% 불투명 다크
  static const Color textDisabled = Color(0x662C2C2C);

  /// 매우 미묘한 상태: 20% 불투명 다크
  static const Color textFaint = Color(0x332C2C2C);

  // ─── 구분선 / 그림자 ──────────────────────────────────────────────────────

  /// 미묘한 구분선: 6% 불투명 블랙
  static const Color dividerSubtle = Color(0x0F000000);

  /// 대시보드 카드 그라디언트 끝 색상 (Soft Coral)
  static const Color gradientEnd = Color(0xFFE88A5A);

  /// Primary 계열 그림자
  static const Color shadowPrimary = Color(0x40F04E23);

  // ─── API 키 배너 ─────────────────────────────────────────────────────────

  /// API 키 안내 배너 배경: 연한 황색
  static const Color bannerWarningBg = Color(0xFFFFF8E1);

  /// API 키 안내 배너 테두리: Amber
  static const Color bannerWarningBorder = Color(0xFFFFD54F);

  /// API 키 안내 배너 제목 색상: 짙은 갈색
  static const Color bannerWarningTitle = Color(0xFF5D4037);

  /// API 키 안내 배너 본문 색상: 갈색
  static const Color bannerWarningBody = Color(0xFF795548);

  /// 이모지 폰트 폴백.
  /// Pretendard에 없는 이모지 글리프를 TwemojiMozilla로 렌더링한다.
  static const List<String> emojiFallback = <String>['TwemojiMozilla'];

  /// 화면 공통 AppBar 타이틀 스타일.
  /// 홈 'WhipUp'과 동일하게 Black(900) + Flame Orange로 통일한다.
  static const TextStyle screenTitleStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w900,
    fontSize: 24,
    color: primaryColor,
    letterSpacing: -0.25,
  );

  // ─── 테마 ─────────────────────────────────────────────────────────────────

  /// 라이트 테마.
  static ThemeData get light => FlexThemeData.light(
        colors: const FlexSchemeColor(
          primary: primaryColor,
          primaryContainer: primaryContainerColor,
          secondary: Color(0xFFFF7043),
          secondaryContainer: Color(0xFFFAFAFA),
          tertiary: Color(0xFF795548),
          tertiaryContainer: Color(0xFFF5F5F5),
          appBarColor: primaryColor,
          error: dangerRed,
        ),
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 0,
        scaffoldBackground: backgroundColor,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 0,
          blendOnColors: false,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
          // 카드 (데모 r4: --radius-card 12)
          cardRadius: 12.0,
          // 버튼
          elevatedButtonRadius: 12.0,
          filledButtonRadius: 12.0,
          outlinedButtonRadius: 12.0,
          textButtonRadius: 8.0,
          // FAB
          fabRadius: 16.0,
          // 칩 (데모 r4: --radius-chip 20, 알약형)
          chipRadius: 20.0,
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
          keepPrimaryContainer: true,
          keepSecondaryContainer: true,
          keepTertiaryContainer: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ).copyWith(
        // ─── 텍스트 스타일 오버라이드 ────────────────────────────────────────
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
        ),
        textTheme: _buildTextTheme(Brightness.light),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFFFFFFFF),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFFFAFAFA),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF04E23), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
          ),
        ),
      );

  /// 다크 테마.
  static ThemeData get dark => FlexThemeData.dark(
        colors: const FlexSchemeColor(
          primary: primaryDarkColor,
          primaryContainer: primaryContainerColor,
          secondary: Color(0xFFFF8A65),
          secondaryContainer: Color(0xFF2A2A2A),
          tertiary: Color(0xFFBCAAA4),
          tertiaryContainer: Color(0xFF262626),
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
          cardRadius: 12.0,
          elevatedButtonRadius: 12.0,
          filledButtonRadius: 12.0,
          outlinedButtonRadius: 12.0,
          textButtonRadius: 8.0,
          fabRadius: 16.0,
          chipRadius: 20.0,
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
          keepPrimaryContainer: true,
          keepSecondaryContainer: true,
          keepTertiaryContainer: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ).copyWith(
        textTheme: _buildTextTheme(Brightness.dark)
            .apply(fontFamilyFallback: emojiFallback),
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
    ).apply(
      // 모든 이모지를 Twemoji 컬러 폰트로 폴백 렌더링하여
      // iOS/Android/Web에서 동일한 모양을 보장한다.
      fontFamilyFallback: const ['TwemojiMozilla'],
    );
  }
}
