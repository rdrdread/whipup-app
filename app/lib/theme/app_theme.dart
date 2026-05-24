import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// WhipUp 디자인 시스템 테마.
/// [FlexColorScheme]을 기반으로 라이트/다크 테마를 정의한다.
///
/// 상세 디자인 토큰은 `docs/core/design_system.md`를 참조.
abstract final class AppTheme {
  /// 라이트 테마
  static ThemeData get light => FlexThemeData.light(
        scheme: FlexScheme.green,
        useMaterial3: true,
        fontFamily: 'Pretendard', // TODO: assets/fonts에 Pretendard 추가 후 활성화
      );

  /// 다크 테마
  static ThemeData get dark => FlexThemeData.dark(
        scheme: FlexScheme.green,
        useMaterial3: true,
        fontFamily: 'Pretendard',
      );
}
