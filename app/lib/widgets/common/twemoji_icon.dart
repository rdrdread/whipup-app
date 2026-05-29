import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 단일 이모지를 Twemoji(Twitter 이모지) SVG로 렌더링하는 위젯.
///
/// `Twemoji` 위젯의 내부 regex 매처를 우회하여 SVG 파일 경로를
/// 직접 생성하므로, 일부 이모지(🧊·🧂·🥬 등)가 매칭 실패로
/// 깨지는 문제를 방지한다.
class TwemojiIcon extends StatelessWidget {
  const TwemojiIcon(this.emoji, {super.key, this.size = 20});

  final String emoji;
  final double size;

  /// 이모지 문자열 → Twemoji 파일명용 codepoint 문자열 변환.
  ///
  /// '️'(variation selector-16)를 제거 후 rune별 16진수를
  /// '-'로 연결한다. (예: '🧊' → '1f9ca', '❄️' → '2744')
  String _assetCode() {
    final stripped = emoji.replaceAll('️', '');
    return stripped.runes.map((cp) => cp.toRadixString(16)).join('-');
  }

  @override
  Widget build(BuildContext context) {
    final code = _assetCode();
    if (code.isEmpty) return SizedBox(width: size, height: size);
    return SvgPicture.asset(
      'assets/svg/$code.svg',
      width: size,
      height: size,
      package: 'flutter_twemoji',
    );
  }
}
