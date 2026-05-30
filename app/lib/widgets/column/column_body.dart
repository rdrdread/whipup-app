import 'package:flutter/material.dart';

/// 칼럼 본문 렌더링 위젯.
///
/// 단락 구분('\n\n')을 처리하여 단락 간 여백을 추가한다.
/// bodyLarge 스타일 적용 (`docs/core/design_system.md §5`).
class ColumnBody extends StatelessWidget {
  const ColumnBody({super.key, required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final paragraphs = body
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final para in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(para, style: style),
          ),
      ],
    );
  }
}
