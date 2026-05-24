import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/stock_filter.dart';
import 'package:whipup/models/stock_item.dart';

/// 재고 저장소 추상 인터페이스.
///
/// Architect가 정의하는 계약. Bridge의 [IsarStockRepository]가 구현한다.
/// 의존성 역전(DIP) 원칙을 준수하여 UI와 Provider는 구현체를 직접 알지 못한다.
///
/// 인터페이스 명세: `docs/core/product_map.md §4.1`
abstract class StockRepository {
  /// 필터를 적용한 전체 재고 목록을 반환한다.
  Future<Result<List<StockItem>, AppError>> getAll(StockFilter filter);

  /// ID로 특정 재고 아이템을 조회한다.
  Future<Result<StockItem, AppError>> getById(int id);

  /// 새 재고 아이템을 저장하고 저장된 아이템을 반환한다.
  Future<Result<StockItem, AppError>> add(StockItem item);

  /// 기존 재고 아이템을 수정한다.
  Future<Result<StockItem, AppError>> update(StockItem item);

  /// ID로 재고 아이템을 삭제한다.
  Future<Result<void, AppError>> delete(int id);

  /// 유통기한 임박([daysThreshold]일 이내) 재고를 반환한다.
  Future<Result<List<StockItem>, AppError>> getExpiringSoon({
    int daysThreshold = 3,
  });

  /// 필터를 적용한 재고 목록 실시간 스트림.
  ///
  /// DB 변경 시 자동으로 최신 데이터를 emit한다.
  Stream<List<StockItem>> watchAll(StockFilter filter);
}
