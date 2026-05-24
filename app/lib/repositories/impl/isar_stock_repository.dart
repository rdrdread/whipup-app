import 'package:isar/isar.dart';
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/models/stock_filter.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/repositories/stock_repository.dart';
import 'isar_stock_item.dart';

/// [StockRepository] Isar 구현체.
///
/// Clean Architecture Bridge 레이어. IsarStockItem ↔ StockItem 변환을 담당.
/// 에러는 모두 [Result] 패턴으로 래핑하여 반환한다.
class IsarStockRepository implements StockRepository {
  const IsarStockRepository(this._isar);

  final Isar _isar;

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<StockItem>, AppError>> getAll(StockFilter filter) async {
    try {
      final items = await _buildQuery(filter).findAll();
      return Result.success(items.map(_toDomain).toList());
    } catch (e) {
      return Result.failure(AppError.database('재고 조회 실패: $e'));
    }
  }

  @override
  Future<Result<StockItem, AppError>> getById(int id) async {
    try {
      final item = await _isar.isarStockItems.get(id);
      if (item == null) {
        return Result.failure(const AppError.database('재고 아이템을 찾을 수 없습니다.'));
      }
      return Result.success(_toDomain(item));
    } catch (e) {
      return Result.failure(AppError.database('재고 조회 실패: $e'));
    }
  }

  @override
  Future<Result<StockItem, AppError>> add(StockItem item) async {
    try {
      final isarItem = _toIsar(item);
      await _isar.writeTxn(() async {
        await _isar.isarStockItems.put(isarItem);
      });
      return Result.success(_toDomain(isarItem));
    } catch (e) {
      return Result.failure(AppError.database('재고 추가 실패: $e'));
    }
  }

  @override
  Future<Result<StockItem, AppError>> update(StockItem item) async {
    try {
      final isarItem = _toIsar(item);
      await _isar.writeTxn(() async {
        await _isar.isarStockItems.put(isarItem);
      });
      return Result.success(_toDomain(isarItem));
    } catch (e) {
      return Result.failure(AppError.database('재고 수정 실패: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> delete(int id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarStockItems.delete(id);
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppError.database('재고 삭제 실패: $e'));
    }
  }

  @override
  Future<Result<List<StockItem>, AppError>> getExpiringSoon({
    int daysThreshold = 3,
  }) async {
    try {
      final threshold = DateTime.now().add(Duration(days: daysThreshold));
      final items = await _isar.isarStockItems
          .where()
          .filter()
          .expiryDateIsNotNull()
          .expiryDateLessThan(threshold)
          .findAll();
      final result = items.map(_toDomain).toList()
        ..sort((a, b) => (a.expiryDate ?? DateTime.now())
            .compareTo(b.expiryDate ?? DateTime.now()));
      return Result.success(result);
    } catch (e) {
      return Result.failure(AppError.database('유통기한 임박 조회 실패: $e'));
    }
  }

  @override
  Stream<List<StockItem>> watchAll(StockFilter filter) {
    return _buildQuery(filter)
        .watch(fireImmediately: true)
        .map((items) => items.map(_toDomain).toList());
  }

  // ─── 내부 헬퍼 ─────────────────────────────────────────────────────────────

  /// 필터 조건을 적용한 Isar 쿼리를 빌드한다.
  QueryBuilder<IsarStockItem, IsarStockItem, QAfterFilterCondition>
      _buildQuery(StockFilter filter) {
    var query = _isar.isarStockItems.where().filter();

    // 보관 위치 필터
    if (filter.storageLocation != null) {
      query = query.storageLocationEqualTo(filter.storageLocation!.name);
    }

    // 카테고리 필터
    if (filter.category != null) {
      query = query.categoryEqualTo(filter.category!.name);
    }

    return query;
  }

  /// [IsarStockItem] → [StockItem] 변환.
  StockItem _toDomain(IsarStockItem item) {
    return StockItem(
      id: item.id,
      name: item.name,
      category: StockCategory.values.firstWhere(
        (c) => c.name == item.category,
        orElse: () => StockCategory.other,
      ),
      subCategory: item.subCategory,
      itemPart: item.itemPart,
      storageLocation: StorageLocation.values.firstWhere(
        (l) => l.name == item.storageLocation,
        orElse: () => StorageLocation.fridge,
      ),
      quantity: item.quantity,
      unit: item.unit,
      expiryDate: item.expiryDate,
      addedAt: item.addedAt,
    );
  }

  /// [StockItem] → [IsarStockItem] 변환.
  IsarStockItem _toIsar(StockItem item) {
    return IsarStockItem()
      ..id = item.id
      ..name = item.name
      ..category = item.category.name
      ..subCategory = item.subCategory
      ..itemPart = item.itemPart
      ..storageLocation = item.storageLocation.name
      ..quantity = item.quantity
      ..unit = item.unit
      ..expiryDate = item.expiryDate
      ..addedAt = item.addedAt;
  }
}
