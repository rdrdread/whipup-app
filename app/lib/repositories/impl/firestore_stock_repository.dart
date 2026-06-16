import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/models/stock_filter.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/repositories/stock_repository.dart';


/// Firestore 기반 재고 저장소.
///
/// 가구 모드에서 사용되며, 모든 구성원이 같은 컬렉션을 공유한다.
///
/// Firestore 경로: `households/{householdId}/stock_items/{itemId}`
///
/// int ID 전략: 신규 아이템은 microsecondsSinceEpoch를 ID로 사용한다.
/// 이 값은 문서 ID(string)로 저장되며, 조회 시 다시 int로 파싱된다.
class FirestoreStockRepository implements StockRepository {
  FirestoreStockRepository({
    required this.householdId,
    required this.userId,
  }) : _collection = FirebaseFirestore.instance
            .collection('households')
            .doc(householdId)
            .collection('stock_items');

  final String householdId;
  final String userId;
  final CollectionReference<Map<String, dynamic>> _collection;

  // ─── 읽기 ─────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<StockItem>, AppError>> getAll(StockFilter filter) async {
    try {
      final snap = await _collection.get();
      final items = snap.docs.map(_docToItem).whereType<StockItem>().toList();
      return Result.success(_applyFilter(items, filter));
    } catch (e) {
      return Result.failure(AppError.database('Firestore 재고 조회 실패: $e'));
    }
  }

  @override
  Future<Result<StockItem, AppError>> getById(int id) async {
    try {
      final doc = await _collection.doc(id.toString()).get();
      if (!doc.exists) {
        return Result.failure(AppError.database('아이템을 찾을 수 없습니다: $id'));
      }
      final item = _docToItem(doc);
      if (item == null) {
        return Result.failure(AppError.database('아이템 파싱 실패: $id'));
      }
      return Result.success(item);
    } catch (e) {
      return Result.failure(AppError.database('Firestore 아이템 조회 실패: $e'));
    }
  }

  @override
  Stream<List<StockItem>> watchAll(StockFilter filter) {
    return _collection.snapshots().map((snap) {
      final items =
          snap.docs.map(_docToItem).whereType<StockItem>().toList();
      return _applyFilter(items, filter);
    });
  }

  // ─── 쓰기 ─────────────────────────────────────────────────────────────────

  @override
  Future<Result<StockItem, AppError>> add(StockItem item) async {
    try {
      final id = DateTime.now().microsecondsSinceEpoch;
      final newItem = item.copyWith(id: id);
      final data = _itemToDoc(newItem);
      await _collection.doc(id.toString()).set(data);
      return Result.success(newItem);
    } catch (e) {
      return Result.failure(AppError.database('Firestore 재고 추가 실패: $e'));
    }
  }

  @override
  Future<Result<StockItem, AppError>> update(StockItem item) async {
    try {
      await _collection.doc(item.id.toString()).set(_itemToDoc(item));
      return Result.success(item);
    } catch (e) {
      return Result.failure(AppError.database('Firestore 재고 수정 실패: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> delete(int id) async {
    try {
      await _collection.doc(id.toString()).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure(AppError.database('Firestore 재고 삭제 실패: $e'));
    }
  }

  @override
  Future<Result<List<StockItem>, AppError>> getExpiringSoon({
    int daysThreshold = 3,
  }) async {
    try {
      final now = DateTime.now();
      final cutoff = now.add(Duration(days: daysThreshold));
      final snap = await _collection.get();
      final items = snap.docs
          .map(_docToItem)
          .whereType<StockItem>()
          .where((item) {
            final expiry = item.expiryDate;
            if (expiry == null) return false;
            return expiry.isAfter(now) && expiry.isBefore(cutoff);
          })
          .toList();
      return Result.success(items);
    } catch (e) {
      return Result.failure(AppError.database('Firestore 임박 재고 조회 실패: $e'));
    }
  }

  // ─── 변환 헬퍼 ─────────────────────────────────────────────────────────────

  StockItem? _docToItem(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      if (data == null) return null;
      // Firestore Timestamp → ISO string 변환
      final normalized = _normalizeFromFirestore(data);
      return StockItem.fromJson(normalized);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _itemToDoc(StockItem item) {
    final json = item.toJson();
    // DateTime ISO string 그대로 저장 (Firestore Timestamp 미사용 — fromJson 호환성 유지)
    return json;
  }

  Map<String, dynamic> _normalizeFromFirestore(Map<String, dynamic> data) {
    final m = Map<String, dynamic>.from(data);
    // Firestore Timestamp가 섞여 있으면 ISO string으로 변환
    for (final key in ['expiryDate', 'addedAt']) {
      final val = m[key];
      if (val is Timestamp) {
        m[key] = val.toDate().toIso8601String();
      }
    }
    return m;
  }

  // ─── 필터 적용 ─────────────────────────────────────────────────────────────

  List<StockItem> _applyFilter(List<StockItem> items, StockFilter filter) {
    var result = items;

    if (filter.storageLocation != null) {
      result = result
          .where((i) => i.storageLocation == filter.storageLocation)
          .toList();
    }

    if (filter.category != null) {
      result = result.where((i) => i.category == filter.category).toList();
    }

    if (filter.containerIndex != null) {
      result = result
          .where((i) => i.containerIndex == filter.containerIndex)
          .toList();
    }

    // 정렬
    result.sort((a, b) {
      int cmp;
      switch (filter.sortBy) {
        case SortType.name:
          cmp = a.name.compareTo(b.name);
        case SortType.addedAt:
          cmp = a.addedAt.compareTo(b.addedAt);
        case SortType.expiryDate:
          final ae = a.expiryDate;
          final be = b.expiryDate;
          if (ae == null && be == null) cmp = 0;
          else if (ae == null) cmp = 1;
          else if (be == null) cmp = -1;
          else cmp = ae.compareTo(be);
      }
      return filter.sortAscending ? cmp : -cmp;
    });

    return result;
  }
}
