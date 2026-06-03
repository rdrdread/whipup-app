import 'package:flutter/material.dart';
import 'package:whipup/models/column_category.dart';

/// 칼럼 카테고리 뱃지 (labelSmall, 라운드 4).
class ColumnCategoryBadge extends StatelessWidget {
  const ColumnCategoryBadge({super.key, required this.category});

  final ColumnCategory category;

  /// 카테고리별 (배경, 전경) 색상.
  static (Color, Color) _colors(ColumnCategory category) {
    return switch (category) {
      ColumnCategory.ingredient =>
        (const Color(0xFFFFF3E0), const Color(0xFFEF6C00)),
      ColumnCategory.science =>
        (const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      ColumnCategory.gardening =>
        (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      ColumnCategory.safety =>
        (const Color(0xFFFFEBEE), const Color(0xFFC62828)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
