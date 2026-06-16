import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 단일 이모지를 Twemoji(Twitter 이모지) SVG로 렌더링하는 위젯.
///
/// SVG 에셋이 없거나 로드 실패 시 시스템 폰트 이모지로 자동 폴백하여
/// 구형 OS나 지원 범위 외 유니코드 이모지(🫘 등)도 깨지지 않도록 한다.
class TwemojiIcon extends StatefulWidget {
  const TwemojiIcon(this.emoji, {super.key, this.size = 20});

  final String emoji;
  final double size;

  @override
  State<TwemojiIcon> createState() => _TwemojiIconState();
}

class _TwemojiIconState extends State<TwemojiIcon> {
  /// SVG 에셋 로드 성공 여부 캐시 (앱 생명주기 동안 유지).
  static final Map<String, bool> _cache = {};

  late Future<bool> _available;

  String get _code {
    final stripped = widget.emoji.replaceAll('️', '');
    return stripped.runes.map((cp) => cp.toRadixString(16)).join('-');
  }

  @override
  void initState() {
    super.initState();
    _available = _checkAvailable();
  }

  Future<bool> _checkAvailable() async {
    final code = _code;
    if (code.isEmpty) return false;
    if (_cache.containsKey(code)) return _cache[code]!;
    try {
      await DefaultAssetBundle.of(context)
          .load('packages/flutter_twemoji/assets/svg/$code.svg');
      _cache[code] = true;
      return true;
    } catch (_) {
      _cache[code] = false;
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _code;
    if (code.isEmpty) return SizedBox(width: widget.size, height: widget.size);

    return FutureBuilder<bool>(
      future: _available,
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return SvgPicture.asset(
            'assets/svg/$code.svg',
            width: widget.size,
            height: widget.size,
            package: 'flutter_twemoji',
          );
        }
        return Text(
          widget.emoji,
          style: TextStyle(fontSize: widget.size * 0.85),
        );
      },
    );
  }
}
