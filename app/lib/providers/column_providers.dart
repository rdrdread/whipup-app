import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:whipup/models/column_article.dart';
import 'package:whipup/models/column_category.dart';
import 'package:whipup/repositories/column_repository.dart';
import 'package:whipup/repositories/impl/local_column_repository.dart';

part 'column_providers.g.dart';

/// ColumnRepository Provider.
@Riverpod(keepAlive: true)
ColumnRepository columnRepository(Ref ref) => LocalColumnRepository();

/// 선택된 카테고리 필터 상태. null이면 "전체".
@riverpod
class ColumnCategoryFilter extends _$ColumnCategoryFilter {
  @override
  ColumnCategory? build() => null;

  /// 카테고리 선택 (null = 전체).
  void select(ColumnCategory? category) => state = category;
}

/// 필터가 적용된 칼럼 목록.
@riverpod
Future<List<ColumnArticle>> filteredColumnList(Ref ref) async {
  final repository = ref.watch(columnRepositoryProvider);
  final category = ref.watch(columnCategoryFilterProvider);

  final result = category == null
      ? await repository.getAll()
      : await repository.getByCategory(category);

  return result.when(
    success: (list) => list,
    failure: (error) => throw error,
  );
}

/// 홈 화면용 최신 칼럼 3개 (카테고리 필터 독립).
@riverpod
Future<List<ColumnArticle>> recentColumns(Ref ref) async {
  final repository = ref.watch(columnRepositoryProvider);
  final result = await repository.getAll();
  return result.when(
    success: (list) => list.take(3).toList(),
    failure: (_) => [],
  );
}

/// 단일 칼럼 상세.
@riverpod
Future<ColumnArticle> columnDetail(Ref ref, String id) async {
  final repository = ref.watch(columnRepositoryProvider);
  final result = await repository.getById(id);

  return result.when(
    success: (article) => article,
    failure: (error) => throw error,
  );
}
