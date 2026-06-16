import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/theme/app_theme.dart';
import 'package:whipup/widgets/common/twemoji_icon.dart';

/// 온보딩 완료 플래그 저장 키.
const _kOnboardingDoneKey = 'onboarding_done';

/// 활성화된 보관 위치 저장 키.
const _kActiveLocationsKey = 'active_locations';

/// Gemini API 키 저장 키.
const _kGeminiApiKey = 'gemini_api_key';

/// 온보딩 화면 (소개 3단계 → API 키 설정 → 보관 공간 설정).
///
/// 앱 최초 실행 시 표시되며, 완료 또는 건너뛰기 시
/// [FlutterSecureStorage]에 완료 여부를 저장하고 홈 화면으로 이동한다.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  final _pageController = PageController();
  int _currentPage = 0;
  Set<StorageLocation> _selectedLocations = Set.from(StorageLocation.values);

  // API 키 입력 상태
  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _apiKeyDetected = false;

  static const _pages = [
    _OnboardingPage(
      emoji: '🧊',
      title: '냉장고 속 재료를\n한눈에 관리해요',
      subtitle: '유통기한 임박 재료를 놓치지 않고\n효율적으로 재고를 관리하세요',
    ),
    _OnboardingPage(
      emoji: '🍳',
      title: '재료에서 레시피로\n뚝딱 변신!',
      subtitle: '보유한 재료를 선택하면 AI가\n맞춤 레시피를 추천해 드려요',
    ),
    _OnboardingPage(
      emoji: '🏆',
      title: '요리할수록\n쌓이는 나만의 기록',
      subtitle: '업적을 달성하며 요리 습관을 만들고\n즐거운 부엌 생활을 시작하세요',
    ),
  ];

  // 소개 3페이지 + API 키 페이지 + 보관 공간 페이지
  int get _totalPages => _pages.length + 2;
  int get _apiKeyPageIndex => _pages.length;       // 3
  int get _containerPageIndex => _pages.length + 1; // 4

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedApiKey();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _apiKeyController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// 이미 저장된 API 키가 있으면 컨트롤러에 채운다.
  Future<void> _loadSavedApiKey() async {
    final stored = await const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ).read(key: _kGeminiApiKey);
    if (stored != null && stored.isNotEmpty && mounted) {
      setState(() => _apiKeyController.text = stored);
    }
  }

  /// 브라우저에서 돌아올 때 클립보드에 API 키 패턴이 있으면 자동 감지한다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _currentPage == _apiKeyPageIndex) {
      _tryPasteFromClipboard();
    }
  }

  /// 클립보드에 'AIza'로 시작하는 문자열이 있으면 자동 붙여넣기한다.
  Future<void> _tryPasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!text.startsWith('AIza') || text.length < 30) return;
    if (_apiKeyController.text.trim() == text) return;
    if (!mounted) return;
    setState(() {
      _apiKeyController.text = text;
      _apiKeyDetected = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _apiKeyDetected = false);
  }

  Future<void> _finishOnboarding() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    await storage.write(key: _kOnboardingDoneKey, value: 'true');
    await storage.write(
      key: _kActiveLocationsKey,
      value: _selectedLocations.map((l) => l.name).join(','),
    );
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    context.go('/home');
  }

  void _toggleLocation(StorageLocation loc) {
    setState(() {
      final updated = Set<StorageLocation>.from(_selectedLocations);
      if (updated.contains(loc) && updated.length > 1) {
        updated.remove(loc);
      } else {
        updated.add(loc);
      }
      _selectedLocations = updated;
    });
  }

  Future<void> _saveApiKeyAndNext() async {
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty) {
      await const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ).write(key: _kGeminiApiKey, value: key);
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentPage == _apiKeyPageIndex) {
      _saveApiKeyAndNext();
    } else {
      _saveLocationsAndNavigate();
    }
  }

  Future<void> _saveLocationsAndNavigate() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    await storage.write(
      key: _kActiveLocationsKey,
      value: _selectedLocations.map((l) => l.name).join(','),
    );
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    context.go('/storage-setup');
  }

  String get _buttonLabel {
    if (_currentPage == _containerPageIndex) return '재고함 설정하기';
    if (_currentPage == _apiKeyPageIndex) return '저장하고 다음으로';
    return '다음';
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ─── 건너뛰기 버튼 ──────────────────────────────────────────
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: isLastPage
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: _finishOnboarding,
                        child: const Text(
                          '건너뛰기',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            color: AppTheme.iconSubtle,
                          ),
                        ),
                      ),
              ),
            ),

            // ─── 페이지뷰 ───────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemCount: _totalPages,
                itemBuilder: (_, index) {
                  if (index < _pages.length) return _pages[index];
                  if (index == _apiKeyPageIndex) {
                    return _ApiKeyPage(
                      controller: _apiKeyController,
                      obscure: _obscureApiKey,
                      detected: _apiKeyDetected,
                      onToggleObscure: () =>
                          setState(() => _obscureApiKey = !_obscureApiKey),
                    );
                  }
                  return _ContainerSetupPage(
                    selected: _selectedLocations,
                    onToggle: _toggleLocation,
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ─── 도트 인디케이터 ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalPages,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primaryColor
                        : AppTheme.textFaint,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ─── 다음 / 시작하기 버튼 ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _buttonLabel,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── API 키 설정 페이지 ────────────────────────────────────────────────────────

/// AI 기능 활성화를 위한 Gemini API 키 입력 페이지 (4번째 온보딩 단계).
class _ApiKeyPage extends StatelessWidget {
  const _ApiKeyPage({
    required this.controller,
    required this.obscure,
    required this.detected,
    required this.onToggleObscure,
  });

  final TextEditingController controller;
  final bool obscure;
  final bool detected;
  final VoidCallback onToggleObscure;

  Future<void> _openAiStudio() async {
    final uri = Uri.parse('https://aistudio.google.com/apikey');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // ─── 헤더 ─────────────────────────────────────────────────
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: TwemojiIcon('🔑', size: 48),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'AI 레시피를 위한\nGemini API 키',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: AppTheme.textStrong,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              '무료로 발급받아 입력하면\nAI 레시피 기능을 모두 사용할 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.6,
                color: AppTheme.iconSubtle,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ─── 발급 가이드 ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.primaryColor.withAlpha(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋  발급 가이드',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                ..._steps.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.$1,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.$2,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              height: 1.5,
                              color: AppTheme.textStrong,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── AI Studio 열기 버튼 ───────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _openAiStudio,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text(
                'Google AI Studio에서 발급받기',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(
                  color: AppTheme.primaryColor.withAlpha(120),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── API 키 입력창 ─────────────────────────────────────────
          TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              color: AppTheme.textStrong,
            ),
            decoration: InputDecoration(
              labelText: 'Gemini API 키',
              labelStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                color: AppTheme.iconSubtle,
              ),
              hintText: 'AIza로 시작하는 키를 붙여넣어 주세요',
              hintStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: AppTheme.textFaint,
              ),
              prefixIcon: const Icon(
                Icons.vpn_key_outlined,
                size: 20,
                color: AppTheme.iconSubtle,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (detected)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppTheme.iconSubtle,
                    ),
                    onPressed: onToggleObscure,
                  ),
                ],
              ),
              filled: true,
              fillColor: AppTheme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppTheme.primaryColor,
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),

          const SizedBox(height: 12),

          // ─── 안내 문구 ─────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppTheme.textFaint,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '브라우저에서 키를 복사하면 앱이 자동으로 감지해요. 나중에 설정 화면에서도 변경할 수 있어요.',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    color: AppTheme.textFaint,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  static const _steps = [
    ('1️⃣', '아래 버튼을 눌러 Google AI Studio를 열어요'),
    ('2️⃣', 'Google 계정으로 로그인해요'),
    ('3️⃣', '[Get API key] → [Create API key]를 탭해요'),
    ('4️⃣', '생성된 키를 복사해요 — 앱으로 돌아오면 자동으로 감지돼요!'),
    ('5️⃣', '아래 입력창에 붙여넣고 [저장하고 다음으로]를 눌러요'),
  ];
}

// ─── 컨테이너 설정 페이지 ─────────────────────────────────────────────────────────

/// 보관 공간 선택 페이지 (5번째 온보딩 단계).
class _ContainerSetupPage extends StatelessWidget {
  const _ContainerSetupPage({
    required this.selected,
    required this.onToggle,
  });

  final Set<StorageLocation> selected;
  final void Function(StorageLocation) onToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: TwemojiIcon('🏠', size: 48),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            '어떤 보관 공간이\n있나요?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: AppTheme.textStrong,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '사용 중인 공간을 선택하면\n재고를 더 스마트하게 관리해요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: AppTheme.iconSubtle,
            ),
          ),
          const SizedBox(height: 28),
          ...StorageLocation.values.map(
            (loc) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LocationToggleCard(
                location: loc,
                isSelected: selected.contains(loc),
                onTap: () => onToggle(loc),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 보관 위치 선택 카드.
class _LocationToggleCard extends StatelessWidget {
  const _LocationToggleCard({
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  final StorageLocation location;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withAlpha(18)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            TwemojiIcon(location.emoji, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.label,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.description,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: AppTheme.iconSubtle,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textFaint,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 온보딩 페이지 ──────────────────────────────────────────────────────────────

/// 개별 온보딩 소개 페이지 위젯.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ─── 이모지 아이콘 ──────────────────────────────────────────
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: TwemojiIcon(emoji, size: 64),
            ),
          ),
          const SizedBox(height: 40),

          // ─── 제목 ───────────────────────────────────────────────────
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: AppTheme.textStrong,
            ),
          ),
          const SizedBox(height: 16),

          // ─── 부제목 ─────────────────────────────────────────────────
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: AppTheme.iconSubtle,
            ),
          ),
        ],
      ),
    );
  }
}
