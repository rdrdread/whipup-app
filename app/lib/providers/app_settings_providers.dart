import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_settings_providers.g.dart';

// ─── 상수 ─────────────────────────────────────────────────────────────────────

const _kThemeModeKey = 'app_theme_mode';

/// 앱 설정 전용 FlutterSecureStorage 인스턴스.
final _appSettingsStorage = FlutterSecureStorage();

/// main()에서 병렬로 미리 읽어 둔 테마 모드.
/// ThemeModeNotifier.build()가 이 값을 우선 반환하므로 SecureStorage 지연이 사라진다.
ThemeMode? _preloadedThemeMode;

/// main()이 호출하는 프리로드 함수.
void preloadThemeMode(String? raw) {
  _preloadedThemeMode = switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

// ─── 테마 모드 Notifier ──────────────────────────────────────────────────────

/// 앱 테마 모드(시스템/라이트/다크) AsyncNotifier.
///
/// [ThemeMode]를 [FlutterSecureStorage]에 영속화하여
/// 앱 재시작 후에도 설정을 유지한다.
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  Future<ThemeMode> build() async {
    final preloaded = _preloadedThemeMode;
    if (preloaded != null) {
      _preloadedThemeMode = null;
      return preloaded;
    }
    final raw = await _appSettingsStorage.read(key: _kThemeModeKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// 테마 모드를 변경하고 [FlutterSecureStorage]에 저장한다.
  Future<void> setThemeMode(ThemeMode mode) async {
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _appSettingsStorage.write(key: _kThemeModeKey, value: raw);
    state = AsyncData(mode);
  }
}
