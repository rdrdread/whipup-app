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
      final domain = items.map(_toDomain).toList();
      return Result.success(_applyContainerFilter(domain, filter));
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
        .map((items) => _applyContainerFilter(items.map(_toDomain).toList(), filter));
  }

  // ─── 내부 헬퍼 ─────────────────────────────────────────────────────────────

  /// 필터 조건을 적용한 Isar 쿼리를 빌드한다.
  ///
  /// storageLocation은 인덱스를 활용한 startsWith 조회를 사용한다.
  /// containerIndex 필터는 인메모리에서 처리한다.
  QueryBuilder<IsarStockItem, IsarStockItem, QAfterFilterCondition>
      _buildQuery(StockFilter filter) {
    if (filter.storageLocation != null) {
      // 인덱스를 활용한 prefix 조회: "fridge", "fridge:0", "fridge:1" 모두 매칭
      var query = _isar.isarStockItems
          .where()
          .storageLocationStartsWith(filter.storageLocation!.name)
          .filter()
          .addedAtGreaterThan(DateTime.fromMillisecondsSinceEpoch(0));
      if (filter.category != null) {
        query = query.and().categoryEqualTo(filter.category!.name);
      }
      return query;
    } else {
      var query = _isar.isarStockItems
          .where()
          .filter()
          .addedAtGreaterThan(DateTime.fromMillisecondsSinceEpoch(0));
      if (filter.category != null) {
        query = query.and().categoryEqualTo(filter.category!.name);
      }
      return query;
    }
  }

  /// containerIndex 인메모리 필터 적용.
  List<StockItem> _applyContainerFilter(List<StockItem> items, StockFilter filter) {
    if (filter.containerIndex == null) return items;
    return items.where((item) => item.containerIndex == filter.containerIndex).toList();
  }

  /// [IsarStockItem] → [StockItem] 변환.
  ///
  /// storageLocation 형식: `"fridge"` (구버전) 또는 `"fridge:0"` (신버전).
  StockItem _toDomain(IsarStockItem item) {
    final parts = item.storageLocation.split(':');
    final locationName = parts[0];
    final containerIdx = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

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
        (l) => l.name == locationName,
        orElse: () => StorageLocation.fridge,
      ),
      containerIndex: containerIdx,
      quantity: item.quantity,
      unit: item.unit,
      expiryDate: item.expiryDate,
      addedAt: item.addedAt,
    );
  }

  /// [StockItem] → [IsarStockItem] 변환.
  ///
  /// storageLocation을 `"fridge:0"` 형식으로 인코딩하여 저장한다.
  IsarStockItem _toIsar(StockItem item) {
    return IsarStockItem()
      ..id = item.id == 0 ? Isar.autoIncrement : item.id
      ..name = item.name
      ..category = item.category.name
      ..subCategory = item.subCategory
      ..itemPart = item.itemPart
      ..storageLocation = '${item.storageLocation.name}:${item.containerIndex}'
      ..quantity = item.quantity
      ..unit = item.unit
      ..expiryDate = item.expiryDate
      ..addedAt = item.addedAt;
  }
}
