import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/providers/storage_config_provider.dart';
import 'package:whipup/theme/app_theme.dart';

/// 온보딩 완료 플래그 저장 키 (onboarding_screen.dart와 동일).
const _kOnboardingDoneKey = 'onboarding_done';

/// 재고함 구성 저장 키. 값 형식: "fridge:1,freezer:1,pantry:1,drawer:1"
const _kStorageConfigKey = 'storage_config';

/// 재고함 설정 화면 (`/storage-setup`).
///
/// 온보딩 직후 사용자가 보유한 재고함 수를 구성한다.
/// 데모 `s-storage-setup` 대응. 구성값은 [FlutterSecureStorage]에 저장되어
/// 추후 컨테이너 단위 기능에서 활용된다.
///
/// 디자인: `docs/core/screen_layout.md §1`
class StorageSetupScreen extends StatefulWidget {
  const StorageSetupScreen({super.key});

  @override
  State<StorageSetupScreen> createState() => _StorageSetupScreenState();
}

class _StorageSetupScreenState extends State<StorageSetupScreen> {
  static const _storage = FlutterSecureStorage();

  /// 보관 위치별 개수 (기본 각 1개).
  final Map<StorageLocation, int> _counts = {
    for (final loc in StorageLocation.values) loc: 1,
  };

  /// 재고함별 사용자 지정 이름. 키: "fridge:0"
  final Map<String, String> _names = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  /// 저장된 구성과 이름을 불러온다.
  Future<void> _loadSaved() async {
    final rawConfig = await _storage.read(key: _kStorageConfigKey);
    if (rawConfig != null && rawConfig.isNotEmpty) {
      for (final entry in rawConfig.split(',')) {
        final parts = entry.split(':');
        if (parts.length != 2) continue;
        final loc = StorageLocation.values
            .where((l) => l.name == parts[0])
            .firstOrNull;
        final count = int.tryParse(parts[1]);
        if (loc != null && count != null) _counts[loc] = count;
      }
    }
    final rawNames = await _storage.read(key: kContainerNamesKey);
    if (rawNames != null && rawNames.isNotEmpty) {
      for (final entry in rawNames.split(',')) {
        final eqIdx = entry.indexOf('=');
        if (eqIdx < 0) continue;
        _names[entry.substring(0, eqIdx)] = entry.substring(eqIdx + 1);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _adjust(StorageLocation loc, int delta) {
    setState(() {
      final next = _counts[loc]! + delta;
      _counts[loc] = next < 0 ? 0 : (next > 99 ? 99 : next);
    });
  }

  Future<void> _finish() async {
    final encoded = StorageLocation.values
        .map((loc) => '${loc.name}:${_counts[loc]}')
        .join(',');
    await _storage.write(key: _kStorageConfigKey, value: encoded);
    await _storage.write(key: _kOnboardingDoneKey, value: 'true');
    // 이름 저장: "fridge:0=냉장고,fridge:1=냉장고 2"
    final namesEncoded = _names.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => '${e.key}=${e.value}')
        .join(',');
    await _storage.write(key: kContainerNamesKey, value: namesEncoded);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('재고함이 설정되었어요! 🎉')),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text('재고함 설정', style: AppTheme.screenTitleStyle),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '사용하는 재고함을 추가해 주세요.',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '나중에 설정에서 변경할 수 있어요.',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          color: Color(0x992C2C2C),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Container(
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
                        child: Column(
                          children: [
                            for (var i = 0;
                                i < StorageLocation.values.length;
                                i++) ...[
                              if (i > 0)
                                const Divider(height: 1, indent: 16),
                              _StorageSection(
                                location: StorageLocation.values[i],
                                count: _counts[StorageLocation.values[i]]!,
                                names: _names,
                                onAdjust: (delta) =>
                                    _adjust(StorageLocation.values[i], delta),
                                onNameChanged: (key, name) =>
                                    setState(() => _names[key] = name),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _finish,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// 보관 위치 섹션 (개수 조절 + 재고함별 이름 편집).
class _StorageSection extends StatelessWidget {
  const _StorageSection({
    required this.location,
    required this.count,
    required this.names,
    required this.onAdjust,
    required this.onNameChanged,
  });

  final StorageLocation location;
  final int count;
  final Map<String, String> names;
  final ValueChanged<int> onAdjust;
  final void Function(String key, String name) onNameChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── 개수 조절 행 ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(location.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.label,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location.description,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: Color(0x992C2C2C),
                      ),
                    ),
                  ],
                ),
              ),
              _CounterButton(
                icon: Icons.remove_rounded,
                onTap: count > 0 ? () => onAdjust(-1) : null,
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _CounterButton(
                icon: Icons.add_rounded,
                onTap: () => onAdjust(1),
              ),
            ],
          ),
        ),
        // ─── 재고함별 이름 편집 (2개 이상일 때 표시) ──────────────────
        if (count > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
            child: Column(
              children: List.generate(count, (i) {
                final key = '${location.name}:$i';
                final defaultLabel = '${location.label} ${i + 1}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _NameField(
                    storageKey: key,
                    hint: defaultLabel,
                    initialValue: names[key] ?? '',
                    onChanged: (v) => onNameChanged(key, v),
                  ),
                );
              }),
            ),
          ),
        if (count == 1) ...[
          // 1개일 때도 이름 편집 가능
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
            child: _NameField(
              storageKey: '${location.name}:0',
              hint: location.label,
              initialValue: names['${location.name}:0'] ?? '',
              onChanged: (v) => onNameChanged('${location.name}:0', v),
            ),
          ),
        ],
      ],
    );
  }
}

/// 재고함 이름 입력 필드.
class _NameField extends StatefulWidget {
  const _NameField({
    required this.storageKey,
    required this.hint,
    required this.initialValue,
    required this.onChanged,
  });

  final String storageKey;
  final String hint;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      style: const TextStyle(fontFamily: 'Pretendard', fontSize: 13),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          color: Color(0x662C2C2C),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x1A000000)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x1A000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }
}

/// 카운터 +/- 버튼.
class _CounterButton extends StatelessWidget {
  const _CounterButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? AppTheme.primaryColor
                : const Color(0x332C2C2C),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppTheme.primaryColor : const Color(0x332C2C2C),
        ),
      ),
    );
  }
}
