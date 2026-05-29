import 'package:flutter/material.dart';
import 'package:whipup/models/source.dart';

/// 칼럼 출처 칩.
///
/// 탭하면 인용 정보(및 URL)를 SnackBar로 표시한다.
/// (외부 브라우저 연동은 url_launcher 도입 후 Phase 2.6+에서 추가)
class SourceChip extends StatelessWidget {
  const SourceChip({super.key, required this.source});

  final Source source;

  void _showCitation(BuildContext context) {
    final hasUrl = source.url != null && source.url!.isNotEmpty;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hasUrl ? '${source.citation}\n${source.url}' : source.citation,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.menu_book_outlined, size: 14),
      label: Text(
        source.citation,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onPressed: () => _showCitation(context),
    );
  }
}
