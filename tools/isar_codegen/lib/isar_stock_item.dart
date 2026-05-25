import 'package:isar/isar.dart';

part 'isar_stock_item.g.dart';

/// Isar DB 컬렉션 — 재고 아이템.
///
/// 도메인 모델 [StockItem]과 분리된 DB 전용 클래스.
/// [IsarStockRepository]가 두 클래스 간 변환을 담당한다.
///
/// Clean Architecture: Bridge 레이어 전용. 다른 레이어에서 직접 사용 금지.
@collection
class IsarStockItem {
  /// Isar 자동 증가 ID
  Id id = Isar.autoIncrement;

  /// 재료명
  @Index(type: IndexType.value)
  late String name;

  /// 카테고리 (enum 값의 String)
  late String category;

  /// 서브 카테고리 (예: 돼지고기)
  String? subCategory;

  /// 부위/종류 (예: 목살)
  String? itemPart;

  /// 보관 위치 (enum 값의 String)
  @Index(type: IndexType.value)
  late String storageLocation;

  /// 수량
  late double quantity;

  /// 단위 (예: g, ml, 개)
  late String unit;

  /// 유통기한 (null = 미입력)
  @Index(type: IndexType.value)
  DateTime? expiryDate;

  /// 등록일
  @Index(type: IndexType.value)
  late DateTime addedAt;
}
