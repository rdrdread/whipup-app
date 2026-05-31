import 'package:flutter/material.dart';
import 'package:whipup/theme/app_theme.dart';

/// 칼럼 본문 렌더링 위젯.
///
/// 단락 구분('\n\n')을 처리하며, `§INFO§emoji§stat§statLabel§description`
/// 형식의 인포그래픽 블록을 시각 카드로 렌더링한다.
class ColumnBody extends StatelessWidget {
  const ColumnBody({super.key, required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final segments = body
        .split('\n\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final seg in segments)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: seg.startsWith('§INFO§')
                ? _InfoCard.parse(context, seg)
                : Text(seg, style: style),
          ),
      ],
    );
  }
}

/// 인포그래픽 카드.
///
/// 파싱 형식: `§INFO§[emoji]§[stat]§[statLabel]§[description]`
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.emoji,
    required this.stat,
    required this.statLabel,
    required this.description,
  });

  final String emoji;
  final String stat;
  final String statLabel;
  final String description;

  static Widget parse(BuildContext context, String raw) {
    // raw: '§INFO§🌡️§4°C§냉장 온도§설명'
    final parts = raw.substring('§INFO§'.length).split('§');
    if (parts.length < 4) {
      return Text(raw,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.65));
    }
    return _InfoCard(
      emoji: parts[0].trim(),
      stat: parts[1].trim(),
      statLabel: parts[2].trim(),
      description: parts[3].trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      stat,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statLabel,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    height: 1.5,
                    color: cs.onSurface.withValues(alpha: 0.75),
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
