import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/models/stock_filter.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/providers/stock_repository_provider.dart';

part 'stock_providers.g.dart';

// ─── 재고 요약 데이터 모델 ────────────────────────────────────────────────────────

/// 홈 대시보드용 재고 요약.
class StockSummary {
  const StockSummary({
    required this.fridgeCount,
    required this.freezerCount,
    required this.pantryCount,
    required this.drawerCount,
    required this.expiringCount,
    required this.expiredCount,
    required this.topCategories,
  });

  final int fridgeCount;
  final int freezerCount;
  final int pantryCount;
  final int drawerCount;

  /// 유통기한 임박 (3일 이내) 수량.
  final int expiringCount;

  /// 유통기한 초과 수량.
  final int expiredCount;

  /// 보유량 상위 카테고리 (최대 4개, count 내림차순).
  final List<(StockCategory, int)> topCategories;

  /// 전체 재고 수량.
  int get totalCount => fridgeCount + freezerCount + pantryCount + drawerCount;

  /// 신선 재고 수량 (임박·초과 제외).
  int get freshCount => (totalCount - expiringCount - expiredCount).clamp(0, totalCount);
}

// ─── 필터 Provider ─────────────────────────────────────────────────────────

/// 재고 목록 필터/정렬 상태 Notifier.
///
/// 보관 위치 탭 전환, 카테고리 필터, 정렬 기준을 관리한다.
@riverpod
class StockFilterNotifier extends _$StockFilterNotifier {
  @override
  StockFilter build() => const StockFilter(); // 초기 탭 = 전체 (storageLocation: null)

  /// 전체 탭: 위치 필터를 초기화한다.
  void clearContainer() {
    state = StockFilter(sortBy: state.sortBy, sortAscending: state.sortAscending);
  }

  /// 보관 위치 탭을 전환한다.
  void setStorageLocation(StorageLocation location) {
    state = state.copyWith(storageLocation: location, containerIndex: 0, category: null);
  }

  /// 보관 위치와 컨테이너 인덱스를 함께 전환한다.
  void setContainer(StorageLocation location, int containerIndex) {
    state = state.copyWith(
      storageLocation: location,
      containerIndex: containerIndex,
      category: null,
    );
  }

  /// 카테고리 필터를 토글한다. 동일 카테고리 탭 시 해제.
  void toggleCategory(StockCategory category) {
    if (state.category == category) {
      state = state.copyWith(category: null);
    } else {
      state = state.copyWith(category: category);
    }
  }

  /// 카테고리 필터를 초기화한다.
  void clearCategory() {
    state = state.copyWith(category: null);
  }

  /// 정렬 기준을 변경한다.
  void setSortBy(SortType sortBy) {
    if (state.sortBy == sortBy) {
      // 같은 기준 재탭 시 오름차순/내림차순 토글
      state = state.copyWith(sortAscending: !state.sortAscending);
    } else {
      state = state.copyWith(sortBy: sortBy, sortAscending: false);
    }
  }

  /// 유통기한 임박 재고 확인용: 전체 탭 + 유통기한 오름차순으로 초기화.
  void setExpiryAscending() {
    state = const StockFilter(
      sortBy: SortType.expiryDate,
      sortAscending: true,
    );
  }
}

// ─── 재고 목록 Stream Provider ─────────────────────────────────────────────

/// 필터가 적용된 재고 목록 실시간 스트림.
///
/// 보관 위치 탭 + 카테고리 필터 + 정렬 조건이 반영된다.
/// Isar 변경 감지로 UI가 자동 갱신된다.
@riverpod
Stream<List<StockItem>> filteredStock(Ref ref) async* {
  final repository = await ref.watch(stockRepositoryProvider.future);
  final filter = ref.watch(stockFilterProvider);

  // 정렬은 메모리에서 처리 (Isar의 복합 정렬 제한 우회)
  yield* repository
      .watchAll(filter)
      .map((items) => _sortItems(items, filter));
}

/// 유통기한 임박 재고 목록 (3일 이내).
@riverpod
Future<List<StockItem>> expiringStock(Ref ref) async {
  final repository = await ref.watch(stockRepositoryProvider.future);
  final result = await repository.getExpiringSoon();
  return result.when(
    success: (items) => items,
    failure: (_) => [],
  );
}

/// 전체 위치 재고 스트림 (레시피 재료 선택용).
///
/// [StockFilter]의 `storageLocation: null`을 이용해 전 위치 재고를 반환한다.
@riverpod
Stream<List<StockItem>> allStock(Ref ref) async* {
  final repository = await ref.watch(stockRepositoryProvider.future);
  yield* repository
      .watchAll(const StockFilter())
      .map((items) => items..sort((a, b) => a.name.compareTo(b.name)));
}

/// 전체 재고 요약 (홈 대시보드 카드 용).
@riverpod
Future<StockSummary> stockSummary(Ref ref) async {
  final repository = await ref.watch(stockRepositoryProvider.future);

  final allResult = await repository.getAll(const StockFilter());
  final all = allResult.valueOrNull ?? [];

  final fridgeCount = all.where((i) => i.storageLocation == StorageLocation.fridge).length;
  final freezerCount = all.where((i) => i.storageLocation == StorageLocation.freezer).length;
  final pantryCount = all.where((i) => i.storageLocation == StorageLocation.pantry).length;
  final drawerCount = all.where((i) => i.storageLocation == StorageLocation.drawer).length;
  final expiringCount = all.where((i) => i.expiryStatus == ExpiryStatus.warning).length;
  final expiredCount = all.where((i) => i.expiryStatus == ExpiryStatus.danger).length;

  final catMap = <StockCategory, int>{};
  for (final item in all) {
    catMap[item.category] = (catMap[item.category] ?? 0) + 1;
  }
  final topCategories = (catMap.entries.map((e) => (e.key, e.value)).toList()
    ..sort((a, b) => b.$2.compareTo(a.$2)))
    .take(4)
    .toList();

  return StockSummary(
    fridgeCount: fridgeCount,
    freezerCount: freezerCount,
    pantryCount: pantryCount,
    drawerCount: drawerCount,
    expiringCount: expiringCount,
    expiredCount: expiredCount,
    topCategories: topCategories,
  );
}

// ─── 정렬 헬퍼 ───────────────────────────────────────────────────────────────

List<StockItem> _sortItems(List<StockItem> items, StockFilter filter) {
  final sorted = List<StockItem>.from(items);
  sorted.sort((a, b) {
    final cmp = switch (filter.sortBy) {
      SortType.name => a.name.compareTo(b.name),
      SortType.expiryDate => _compareExpiry(a.expiryDate, b.expiryDate),
      SortType.addedAt => a.addedAt.compareTo(b.addedAt),
    };
    return filter.sortAscending ? cmp : -cmp;
  });
  return sorted;
}

int _compareExpiry(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1; // null은 뒤로
  if (b == null) return -1;
  return a.compareTo(b);
}
