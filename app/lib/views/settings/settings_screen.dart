import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whipup/providers/app_settings_providers.dart';
import 'package:whipup/theme/app_theme.dart';

/// 앱 설정 화면.
///
/// - 테마 전환 (시스템/라이트/다크) — 칩 선택형
/// - 알림 설정 (유통기한 알림, 알림 기준일, 칼럼 알림)
/// - Gemini API 키 설정
/// - 앱 정보
///
/// 레이아웃: `docs/core/screen_layout.md §3.7`, 데모 `s-settings`
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _storage = FlutterSecureStorage();
  static const _kGeminiApiKey = 'gemini_api_key';
  static const _kExpiryAlert = 'notif_expiry_on';
  static const _kColumnAlert = 'notif_column_on';
  static const _kAlertDays = 'notif_days_before';

  final _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;
  bool _apiKeySaved = false;
  bool _loadingApiKey = true;

  // 알림 설정 (로컬 영속).
  bool _expiryAlertOn = true;
  bool _columnAlertOn = true;
  int _alertDaysBefore = 3;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 저장된 설정(API 키 + 알림)을 불러온다.
  Future<void> _loadSettings() async {
    final apiKey = await _storage.read(key: _kGeminiApiKey);
    final expiry = await _storage.read(key: _kExpiryAlert);
    final column = await _storage.read(key: _kColumnAlert);
    final days = await _storage.read(key: _kAlertDays);
    if (!mounted) return;
    setState(() {
      if (apiKey != null) _apiKeyController.text = apiKey;
      _loadingApiKey = false;
      _expiryAlertOn = expiry != 'false';
      _columnAlertOn = column != 'false';
      _alertDaysBefore = int.tryParse(days ?? '') ?? 3;
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

  Future<void> _setExpiryAlert(bool value) async {
    setState(() => _expiryAlertOn = value);
    await _storage.write(key: _kExpiryAlert, value: '$value');
  }

  Future<void> _setColumnAlert(bool value) async {
    setState(() => _columnAlertOn = value);
    await _storage.write(key: _kColumnAlert, value: '$value');
  }

  Future<void> _setAlertDays(int value) async {
    setState(() => _alertDaysBefore = value);
    await _storage.write(key: _kAlertDays, value: '$value');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeModeAsync = ref.watch(themeModeNotifierProvider);
    final currentThemeMode = themeModeAsync.asData?.value ?? ThemeMode.system;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          '설정',
          style: AppTheme.screenTitleStyle,
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ─── 테마 설정 (칩 선택형) ─────────────────────────────────────
          const _SectionHeader(label: '테마'),
          _SettingsCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _ThemeChip(
                    label: '시스템',
                    selected: currentThemeMode == ThemeMode.system,
                    onTap: () => _setTheme(ThemeMode.system),
                  ),
                  const SizedBox(width: 8),
                  _ThemeChip(
                    label: '라이트',
                    selected: currentThemeMode == ThemeMode.light,
                    onTap: () => _setTheme(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _ThemeChip(
                    label: '다크',
                    selected: currentThemeMode == ThemeMode.dark,
                    onTap: () => _setTheme(ThemeMode.dark),
                  ),
                ],
              ),
            ),
          ),

          // ─── 알림 설정 ────────────────────────────────────────────────
          const _SectionHeader(label: '알림'),
          _SettingsCard(
            child: Column(
              children: [
                _SwitchRow(
                  label: '유통기한 알림',
                  value: _expiryAlertOn,
                  onChanged: _setExpiryAlert,
                ),
                const Divider(height: 1, indent: 16),
                _AlertDaysRow(
                  value: _alertDaysBefore,
                  enabled: _expiryAlertOn,
                  onChanged: _setAlertDays,
                ),
                const Divider(height: 1, indent: 16),
                _SwitchRow(
                  label: '칼럼 알림',
                  value: _columnAlertOn,
                  onChanged: _setColumnAlert,
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
              children: [
                const _InfoRow(label: '버전', value: '1.0.0'),
                const Divider(height: 1, indent: 16),
                _NavRow(
                  label: '오픈소스 라이선스',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'WhipUp',
                    applicationVersion: '1.0.0',
                  ),
                ),
                const Divider(height: 1, indent: 16),
                _NavRow(
                  label: '개인정보 처리방침',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('개인정보 처리방침 준비 중이에요')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setTheme(ThemeMode mode) {
    ref.read(themeModeNotifierProvider.notifier).setThemeMode(mode);
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
        color: Colors.white,
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

/// 테마 선택 칩 (알약형).
class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryColor
                : const Color(0xFFF5F0E8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF2C2C2C),
            ),
          ),
        ),
      ),
    );
  }
}

/// 토글 스위치 행.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
            ),
          ),
          Switch(
            value: value,
            activeColor: AppTheme.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// 알림 기준일 선택 행.
class _AlertDaysRow extends StatelessWidget {
  const _AlertDaysRow({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  static const _options = [1, 2, 3, 5, 7];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '알림 기준일',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              color: enabled ? const Color(0xFF2C2C2C) : const Color(0x662C2C2C),
            ),
          ),
          PopupMenuButton<int>(
            enabled: enabled,
            initialValue: value,
            onSelected: onChanged,
            itemBuilder: (context) => _options
                .map((d) => PopupMenuItem<int>(
                      value: d,
                      child: Text('$d일 전'),
                    ))
                .toList(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value일 전',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? AppTheme.primaryColor
                        : const Color(0x662C2C2C),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color:
                      enabled ? AppTheme.primaryColor : const Color(0x662C2C2C),
                ),
              ],
            ),
          ),
        ],
      ),
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

/// 탭하면 이동하는 행 (chevron 표시).
class _NavRow extends StatelessWidget {
  const _NavRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: Color(0x992C2C2C),
            ),
          ],
        ),
      ),
    );
  }
}
