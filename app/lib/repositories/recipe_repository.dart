import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/models/stock_item.dart';

/// 요리 히스토리 항목 (완료된 레시피 + 완료 시각 + 사진 경로).
class RecipeHistoryEntry {
  const RecipeHistoryEntry({
    required this.recipe,
    required this.cookedAt,
    this.photoPath,
  });

  final Recipe recipe;
  final DateTime cookedAt;
  final String? photoPath;
}

/// 레시피 저장소 추상 인터페이스.
///
/// 캐시 우선순위: Local(Isar) → Server(Phase 2.0+) → AI(Gemini)
/// 인터페이스 명세: `docs/core/product_map.md §4.2`
abstract class RecipeRepository {
  /// 재고 재료 기반 레시피 생성 또는 캐시 조회.
  ///
  /// 1. Local 캐시 조회 → Hit: 반환
  /// 2. AI(Gemini) 생성 → Local 캐시 저장 → 반환
  Future<Result<Recipe, AppError>> generateFromStock(
    List<StockItem> items, {
    String? recipeType,
    String? difficulty,
    int servings = 2,
  });

  /// 로컬 캐시 전체 레시피 목록.
  Future<Result<List<Recipe>, AppError>> getCached();

  /// 레시피를 로컬 캐시에 저장한다.
  Future<Result<void, AppError>> saveToCache(Recipe recipe);

  /// 즐겨찾기 토글 (on/off).
  Future<Result<void, AppError>> toggleFavorite(String recipeId);

  /// 즐겨찾기 레시피 목록.
  Future<Result<List<Recipe>, AppError>> getFavorites();

  /// ID로 레시피 상세 조회 (캐시에서).
  Future<Result<Recipe, AppError>> getById(String recipeId);

  /// 레시피 완료 처리 (이벤트 발행 — Reward 연동용).
  Future<Result<void, AppError>> markCompleted(String recipeId);

  /// 요리명으로 레시피 조회 또는 AI 생성.
  ///
  /// 1. 제목으로 캐시 조회 → Hit: 반환
  /// 2. AI 생성 → 캐시 저장 → 반환
  Future<Result<Recipe, AppError>> generateByName(
    String dishName, {
    int servings = 2,
  });

  /// 요리 영상 URL에서 레시피를 AI로 추출하고 캐시에 저장한다.
  Future<Result<Recipe, AppError>> generateFromVideo(String videoUrl);

  /// 레시피를 로컬 캐시 + 백엔드 서버에 업데이트한다.
  Future<Result<Recipe, AppError>> updateRecipe(Recipe recipe);

  /// 요리 완료 데이터(사진 경로, 완료 시각)를 업데이트한다.
  Future<Result<void, AppError>> updateCompletionData(
    String recipeId, {
    String? photoPath,
    DateTime? completedAt,
  });

  /// 완료된 요리 히스토리 목록 (최신순).
  Future<Result<List<RecipeHistoryEntry>, AppError>> getHistory();
}
