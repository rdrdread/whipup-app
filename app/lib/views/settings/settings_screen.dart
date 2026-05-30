import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whipup/providers/app_settings_providers.dart';
import 'package:whipup/theme/app_theme.dart';

/// 앱 설정 화면.
///
/// - 테마 전환 (시스템/라이트/다크)
/// - Gemini API 키 설정
/// - 앱 정보
///
/// 레이아웃: `docs/core/screen_layout.md §2.3`
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _storage = FlutterSecureStorage();
  static const _kGeminiApiKey = 'gemini_api_key';

  final _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;
  bool _apiKeySaved = false;
  bool _loadingApiKey = true;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  /// 저장된 Gemini API 키를 입력 필드에 불러온다.
  Future<void> _loadApiKey() async {
    final key = await _storage.read(key: _kGeminiApiKey);
    if (!mounted) return;
    setState(() {
      if (key != null) _apiKeyController.text = key;
      _loadingApiKey = false;
    });
  }

  /// Gemini API 키를 [FlutterSecureStorage]에 저장한다.
  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;
    await _storage.write(key: _kGeminiApiKey, value: key);
    if (!mounted) return;
    setState(() => _apiKeySaved = true);
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API 키가 저장되었어요 ✅')),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _apiKeySaved = false);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeModeAsync = ref.watch(themeModeProvider);
    final currentThemeMode = themeModeAsync.asData?.value ?? ThemeMode.system;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAF8),
        elevation: 0,
        title: const Text(
          '설정',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ─── 테마 설정 ────────────────────────────────────────────────
          const _SectionHeader(label: '테마'),
          _SettingsCard(
            child: Column(
              children: [
                _ThemeRadioTile(
                  mode: ThemeMode.system,
                  label: '시스템 기본',
                  icon: Icons.settings_system_daydream_outlined,
                  groupValue: currentThemeMode,
                  onChanged: _setTheme,
                ),
                const Divider(height: 1, indent: 16),
                _ThemeRadioTile(
                  mode: ThemeMode.light,
                  label: '라이트 모드',
                  icon: Icons.light_mode_outlined,
                  groupValue: currentThemeMode,
                  onChanged: _setTheme,
                ),
                const Divider(height: 1, indent: 16),
                _ThemeRadioTile(
                  mode: ThemeMode.dark,
                  label: '다크 모드',
                  icon: Icons.dark_mode_outlined,
                  groupValue: currentThemeMode,
                  onChanged: _setTheme,
                ),
              ],
            ),
          ),

          // ─── AI 설정 ──────────────────────────────────────────────────
          const _SectionHeader(label: 'AI 설정'),
          _SettingsCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gemini API 키',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'AI 레시피 추천을 사용하려면\nGoogle AI Studio에서 발급한 API 키를 입력하세요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: Color(0x992C2C2C),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loadingApiKey)
                    const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _apiKeyController,
                            obscureText: _apiKeyObscured,
                            decoration: InputDecoration(
                              hintText: 'AIza...',
                              hintStyle: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                color: Color(0x662C2C2C),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _apiKeyObscured
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _apiKeyObscured = !_apiKeyObscured,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _apiKeySaved ? null : _saveApiKey,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              disabledBackgroundColor:
                                  AppTheme.primaryColor.withAlpha(100),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            child: Text(
                              _apiKeySaved ? '저장됨' : '저장',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // ─── 앱 정보 ──────────────────────────────────────────────────
          const _SectionHeader(label: '앱 정보'),
          _SettingsCard(
            child: Column(
              children: const [
                _InfoRow(label: '버전', value: 'v0.1.0'),
                Divider(height: 1, indent: 16),
                _InfoRow(label: '개발', value: 'WhipUp Team'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setTheme(ThemeMode? mode) {
    if (mode != null) {
      ref.read(themeModeProvider.notifier).setThemeMode(mode);
    }
  }
}

// ─── 헬퍼 위젯 ─────────────────────────────────────────────────────────────────

/// 섹션 헤더 라벨.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0x992C2C2C),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// 설정 카드 컨테이너.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// 테마 RadioListTile.
class _ThemeRadioTile extends StatelessWidget {
  const _ThemeRadioTile({
    required this.mode,
    required this.label,
    required this.icon,
    required this.groupValue,
    required this.onChanged,
  });

  final ThemeMode mode;
  final String label;
  final IconData icon;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode?> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: groupValue,
      activeColor: AppTheme.primaryColor,
      title: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
            ),
          ),
        ],
      ),
      onChanged: onChanged,
    );
  }
}

/// 정보 행 (레이블 + 값).
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              color: Color(0x992C2C2C),
            ),
          ),
        ],
      ),
    );
  }
}
