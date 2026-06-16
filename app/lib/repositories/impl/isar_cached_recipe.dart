import 'package:isar/isar.dart';

part 'isar_cached_recipe.g.dart';

/// Isar DB 컬렉션 — 캐시된 레시피.
///
/// 레시피 전체 데이터를 JSON 문자열로 저장하여
/// 복잡한 중첩 스키마 없이 빠른 캐시 조회를 지원한다.
///
/// Clean Architecture: Bridge 레이어 전용. 다른 레이어에서 직접 사용 금지.
@collection
class IsarCachedRecipe {
  /// Isar 자동 증가 ID
  Id id = Isar.autoIncrement;

  /// 레시피 고유 ID (UUID)
  @Index(type: IndexType.value, unique: true)
  late String recipeId;

  /// 레시피 이름
  @Index(type: IndexType.value)
  late String title;

  /// 레시피 타입 (RecipeType.name)
  @Index(type: IndexType.value)
  late String recipeTypeValue;

  /// 전체 레시피 JSON 직렬화 문자열
  late String jsonData;

  /// 캐시 저장 시각
  @Index(type: IndexType.value)
  late DateTime cachedAt;

  /// 즐겨찾기 여부
  @Index(type: IndexType.value)
  bool isFavorite = false;

  /// 완료 처리 여부
  bool isCompleted = false;

  /// 요리 완료 시각 (null이면 미완료 또는 이전 버전 데이터)
  DateTime? completedAt;

  /// 완료 시 촬영한 사진 파일 경로 (null이면 사진 없음)
  String? photoPath;
}
