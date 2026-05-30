import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:whipup/models/stock_category.dart';
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

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  /// 저장된 구성을 불러온다.
  Future<void> _loadSaved() async {
    final raw = await _storage.read(key: _kStorageConfigKey);
    if (raw != null && raw.isNotEmpty) {
      for (final entry in raw.split(',')) {
        final parts = entry.split(':');
        if (parts.length != 2) continue;
        StorageLocation? loc;
        for (final l in StorageLocation.values) {
          if (l.name == parts[0]) {
            loc = l;
            break;
          }
        }
        final count = int.tryParse(parts[1]);
        if (loc != null && count != null) _counts[loc] = count;
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
                              _StorageRow(
                                location: StorageLocation.values[i],
                                count: _counts[StorageLocation.values[i]]!,
                                onAdjust: (delta) =>
                                    _adjust(StorageLocation.values[i], delta),
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

/// 재고함 행 (이모지 + 이름/설명 + 카운터).
class _StorageRow extends StatelessWidget {
  const _StorageRow({
    required this.location,
    required this.count,
    required this.onAdjust,
  });

  final StorageLocation location;
  final int count;
  final ValueChanged<int> onAdjust;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
