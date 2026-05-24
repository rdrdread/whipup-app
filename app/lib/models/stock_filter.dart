import 'package:freezed_annotation/freezed_annotation.dart';
import 'stock_category.dart';

part 'stock_filter.freezed.dart';

/// 재고 목록 필터 및 정렬 상태.
///
/// `stockFilterNotifierProvider`가 이 모델을 상태로 관리한다.
/// 필터 정의: `docs/features/inventory_management.md §4.3`
@freezed
class StockFilter with _$StockFilter {
  const factory StockFilter({
    /// 카테고리 필터. null이면 전체 표시.
    StockCategory? category,

    /// 보관 위치 필터. null이면 전체 (탭과 연동).
    StorageLocation? storageLocation,

    /// 정렬 기준.
    @Default(SortType.addedAt) SortType sortBy,

    /// 오름차순 여부.
    @Default(false) bool sortAscending,
  }) = _StockFilter;
}
