import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whipup/providers/auth_providers.dart';
import 'package:whipup/providers/household_providers.dart';
import 'package:whipup/providers/recipe_providers.dart';
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

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _kGeminiApiKey = 'gemini_api_key';
  static const _kColumnAlert = 'notif_column_on';
  static const _kAlertDays = 'notif_days_before';

  final _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;
  bool _apiKeySaved = false;
  bool _loadingApiKey = true;

  // 알림 설정 (로컬 영속).
  bool _columnAlertOn = true;
  int _alertDaysBefore = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  /// 브라우저에서 돌아올 때 클립보드에 API 키가 있으면 자동 감지한다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tryPasteFromClipboard();
    }
  }

  /// 저장된 설정(API 키 + 알림)을 불러온다.
  Future<void> _loadSettings() async {
    final apiKey = await _storage.read(key: _kGeminiApiKey);
    final column = await _storage.read(key: _kColumnAlert);
    final days = await _storage.read(key: _kAlertDays);
    if (!mounted) return;
    setState(() {
      if (apiKey != null) _apiKeyController.text = apiKey;
      _loadingApiKey = false;
      _columnAlertOn = column != 'false';
      _alertDaysBefore = int.tryParse(days ?? '') ?? 3;
    });
  }

  /// Gemini API 키를 [FlutterSecureStorage]에 저장한다.
  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;
    await _storage.write(key: _kGeminiApiKey, value: key);
    // 레시피 화면 API 키 상태 배너를 즉시 갱신한다.
    ref.invalidate(geminiApiKeyStatusProvider);
    if (!mounted) return;
    setState(() => _apiKeySaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API 키가 저장되었어요 ✅')),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _apiKeySaved = false);
  }

  /// AI Studio 페이지를 외부 브라우저로 연다.
  Future<void> _openAiStudio() async {
    final uri = Uri.parse('https://aistudio.google.com/apikey');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 클립보드에 Gemini API 키 패턴(AIza...)이 있으면 자동 붙여넣기한다.
  Future<void> _tryPasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    // Gemini API 키는 'AIza'로 시작하며 39자
    if (!text.startsWith('AIza') || text.length < 30) return;
    // 이미 같은 값이면 무시
    if (_apiKeyController.text.trim() == text) return;
    if (!mounted) return;
    setState(() => _apiKeyController.text = text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('클립보드에서 API 키를 감지했어요'),
        action: SnackBarAction(label: '저장', onPressed: _saveApiKey),
        duration: const Duration(seconds: 5),
      ),
    );
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
    WidgetsBinding.instance.removeObserver(this);
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          // ─── 계정 ─────────────────────────────────────────────────────
          const _SectionHeader(label: '계정'),
          const _AccountSection(storage: _storage),

          // ─── 가구 공유 ────────────────────────────────────────────────
          const _SectionHeader(label: '가구 공유'),
          const _HouseholdSection(),

          // ─── 알림 설정 ────────────────────────────────────────────────
          const _SectionHeader(label: '알림'),
          _SettingsCard(
            child: Column(
              children: [
                _AlertDaysRow(
                  value: _alertDaysBefore,
                  enabled: true,
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
                  // ── 헤더 + 발급받기 링크 ──────────────────────────────
                  Row(
                    children: [
                      const Text(
                        'Gemini API 키',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openAiStudio,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.flameOrange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new_rounded,
                                  size: 13, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                '발급받기',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Google AI Studio에서 발급 → 복사 후 앱으로 돌아오면\n자동으로 붙여넣어요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: AppTheme.iconSubtle,
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── 입력 필드 ──────────────────────────────────
                        Expanded(
                          child: TextField(
                            controller: _apiKeyController,
                            obscureText: _apiKeyObscured,
                            decoration: InputDecoration(
                              hintText: 'AIza...',
                              hintStyle: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                color: AppTheme.textDisabled,
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
                        const SizedBox(width: 6),
                        // ── 클립보드 붙여넣기 ───────────────────────────
                        SizedBox(
                          height: 48,
                          width: 48,
                          child: IconButton.outlined(
                            onPressed: _tryPasteFromClipboard,
                            icon: const Icon(Icons.content_paste_rounded,
                                size: 20),
                            tooltip: '클립보드에서 붙여넣기',
                            style: IconButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(
                                  color: AppTheme.primaryColor, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // ── 저장 버튼 ──────────────────────────────────
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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

}

// ─── 헬퍼 위젯 ─────────────────────────────────────────────────────────────────

/// 계정 섹션 — 로그인된 사용자 정보 + 로그아웃 버튼.
class _AccountSection extends ConsumerWidget {
  const _AccountSection({required this.storage});
  final FlutterSecureStorage storage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider).asData?.value;

    return _SettingsCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: appUser?.photoUrl != null
                      ? NetworkImage(appUser!.photoUrl!)
                      : null,
                  child: appUser?.photoUrl == null
                      ? const Icon(Icons.person_rounded, size: 22)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appUser?.displayName ?? '로그인 중...',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (appUser?.email != null)
                        Text(
                          appUser!.email,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            color: AppTheme.iconSubtle,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16),
          _NavRow(
            label: '로그아웃',
            onTap: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하면 로그인 화면으로 이동해요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(authServiceProvider).signOut();
    await storage.delete(key: 'onboarding_done');
    if (context.mounted) context.go('/login');
  }
}

/// 가구 공유 섹션 — 현재 가구 상태 + 관리 화면 진입.
class _HouseholdSection extends ConsumerWidget {
  const _HouseholdSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(currentHouseholdProvider);

    return _SettingsCard(
      child: _NavRow(
        label: '가구 관리',
        subtitle: householdAsync.when(
          data: (h) => h != null ? h.name : '가구에 속해 있지 않아요',
          loading: () => '로딩 중...',
          error: (_, __) => '오류',
        ),
        onTap: () => context.push('/household'),
      ),
    );
  }
}

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
          color: AppTheme.iconSubtle,
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
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.dividerSubtle,
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
              color: enabled ? AppTheme.textDark : AppTheme.textDisabled,
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
                        : AppTheme.textDisabled,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color:
                      enabled ? AppTheme.primaryColor : AppTheme.textDisabled,
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
              color: AppTheme.iconSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

/// 탭하면 이동하는 행 (chevron 표시).
class _NavRow extends StatelessWidget {
  const _NavRow({required this.label, required this.onTap, this.subtitle});
  final String label;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: AppTheme.iconSubtle,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppTheme.iconSubtle,
            ),
          ],
        ),
      ),
    );
  }
}
