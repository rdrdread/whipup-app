/// 위클리 칼럼 카테고리.
///
/// 데이터 계약은 `docs/core/product_map.md §3.3` 및
/// `docs/features/weekly_column.md §3.2` 참조.
enum ColumnCategory {
  ingredient('재료', '🥕'),
  science('과학', '🔬'),
  culture('문화', '🍜'),
  safety('안전', '🛡️'),
  seasonal('제철', '🌿');

  const ColumnCategory(this.label, this.emoji);

  /// 한글 표시명
  final String label;

  /// 대표 이모지
  final String emoji;
}
