import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'stock_category.dart';

part 'stock_item.freezed.dart';
part 'stock_item.g.dart';

/// 재고 아이템 도메인 모델.
///
/// Isar 자동 ID를 사용한다. 신규 아이템은 [id] = 0으로 생성하며,
/// 저장 후 실제 ID가 할당된다.
///
/// 필드 정의: `docs/core/product_map.md §3.1`
@freezed
abstract class StockItem with _$StockItem {
  const StockItem._(); // 커스텀 메서드를 위한 private 생성자

  /// 새 재고 아이템을 생성한다.
  const factory StockItem({
    /// Isar 자동 증가 ID. 신규 아이템은 0으로 설정.
    @Default(0) int id,

    /// 재료명 (예: "돼지고기 (목살)")
    required String name,

    /// 카테고리 (예: StockCategory.meat)
    required StockCategory category,

    /// 서브 카테고리 (예: "돼지고기")
    String? subCategory,

    /// 부위/종류 (예: "목살")
    @JsonKey(name: 'part') String? itemPart,

    /// 보관 위치
    required StorageLocation storageLocation,

    /// 수량
    @Default(1.0) double quantity,

    /// 단위 (예: "g", "ml", "개")
    @Default('개') String unit,

    /// 유통기한 (null = 입력 안 함)
    DateTime? expiryDate,

    /// 등록일
    required DateTime addedAt,

    /// 재고함 인덱스 (0-based, 동일 보관 위치 내 여러 재고함 구분)
    @Default(0) int containerIndex,
  }) = _StockItem;

  factory StockItem.fromJson(Map<String, dynamic> json) =>
      _$StockItemFromJson(json);

  // ─── 커스텀 Getter ─────────────────────────────────────────────────────────

  /// 유통기한 상태 (fresh / warning / danger).
  ExpiryStatus get expiryStatus => ExpiryStatus.fromExpiryDate(expiryDate);

  /// D-day 표시 문자열.
  String get dDayLabel => expiryStatus.dDayLabel(expiryDate);

  /// 신규 아이템 여부 (Isar에 저장되지 않은 상태).
  bool get isNew => id == 0;

  /// 재료명 전체 표시 (subCategory + itemPart 포함).
  String get displayName {
    if (subCategory != null && itemPart != null) {
      return '$subCategory ($itemPart)';
    }
    if (subCategory != null) return subCategory!;
    return name;
  }
}
