import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/repositories/recipe_repository.dart';
import 'package:whipup/services/recipe_generation_service.dart';
import 'isar_cached_recipe.dart';

/// [RecipeRepository] Isar 구현체.
///
/// 레시피를 JSON 문자열로 로컬 캐시에 저장하고 조회한다.
/// AI 생성은 [RecipeGenerationService]에 위임한다.
class IsarRecipeRepository implements RecipeRepository {
  const IsarRecipeRepository({
    required Isar isar,
    required RecipeGenerationService generationService,
  })  : _isar = isar, // ignore: prefer_initializing_formals
        _generation = generationService;

  final Isar _isar;
  final RecipeGenerationService _generation;

  @override
  Future<Result<Recipe, AppError>> generateFromStock(
    List<StockItem> items, {
    String? recipeType,
    String? difficulty,
    int servings = 2,
  }) async {
    return _generation.generateRecipe(
      items: items,
      recipeType: recipeType,
      difficulty: difficulty,
      servings: servings,
    );
  }

  @override
  Future<Result<List<Recipe>, AppError>> getCached() async {
    try {
      final items = await _isar.isarCachedRecipes
          .where()
          .sortByCachedAtDesc()
          .findAll();
      final recipes = items.map(_toDomain).whereType<Recipe>().toList();
      return Result.success(recipes);
    } catch (e) {
      return Result.failure(AppError.database('레시피 캐시 조회 실패: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> saveToCache(Recipe recipe) async {
    try {
      await _isar.writeTxn(() async {
        final existing = await _isar.isarCachedRecipes
            .where()
            .recipeIdEqualTo(recipe.id)
            .findFirst();
        final item = IsarCachedRecipe()
          ..id = existing?.id ?? Isar.autoIncrement
          ..recipeId = recipe.id
          ..title = recipe.title
          ..recipeTypeValue = recipe.recipeType.name
          ..jsonData = json.encode(recipe.toJson())
          ..cachedAt = existing?.cachedAt ?? DateTime.now()
          ..isFavorite = existing?.isFavorite ?? false
          ..isCompleted = existing?.isCompleted ?? false;
        await _isar.isarCachedRecipes.put(item);
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppError.database('레시피 저장 실패: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> toggleFavorite(String recipeId) async {
    try {
      await _isar.writeTxn(() async {
        final item = await _isar.isarCachedRecipes
            .where()
            .recipeIdEqualTo(recipeId)
            .findFirst();
        if (item != null) {
          item.isFavorite = !item.isFavorite;
          await _isar.isarCachedRecipes.put(item);
        }
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppError.database('즐겨찾기 토글 실패: $e'));
    }
  }

  @override
  Future<Result<List<Recipe>, AppError>> getFavorites() async {
    try {
      final items = await _isar.isarCachedRecipes
          .where()
          .filter()
          .isFavoriteEqualTo(true)
          .sortByCachedAtDesc()
          .findAll();
      final recipes = items.map(_toDomain).whereType<Recipe>().toList();
      return Result.success(recipes);
    } catch (e) {
      return Result.failure(AppError.database('즐겨찾기 조회 실패: $e'));
    }
  }

  @override
  Future<Result<Recipe, AppError>> getById(String recipeId) async {
    try {
      final item = await _isar.isarCachedRecipes
          .where()
          .recipeIdEqualTo(recipeId)
          .findFirst();
      if (item == null) {
        return const Result.failure(AppError.database('레시피를 찾을 수 없습니다.'));
      }
      final recipe = _toDomain(item);
      if (recipe == null) {
        return const Result.failure(AppError.parsing('레시피 데이터가 손상되었습니다.'));
      }
      return Result.success(recipe);
    } catch (e) {
      return Result.failure(AppError.database('레시피 조회 실패: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> markCompleted(String recipeId) async {
    try {
      await _isar.writeTxn(() async {
        final item = await _isar.isarCachedRecipes
            .where()
            .recipeIdEqualTo(recipeId)
            .findFirst();
        if (item != null) {
          item.isCompleted = true;
          await _isar.isarCachedRecipes.put(item);
        }
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppError.database('레시피 완료 처리 실패: $e'));
    }
  }

  Recipe? _toDomain(IsarCachedRecipe item) {
    try {
      final map = json.decode(item.jsonData) as Map<String, dynamic>;
      return Recipe.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
