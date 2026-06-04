import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/repositories/recipe_repository.dart';
import 'package:whipup/services/recipe_generation_service.dart';
import 'package:whipup/services/recipe_server_service.dart';
import 'isar_cached_recipe.dart';

/// [RecipeRepository] Isar 구현체.
///
/// 캐싱 레이어: Local(Isar) → Server([RecipeServerService]) → AI([RecipeGenerationService])
class IsarRecipeRepository implements RecipeRepository {
  const IsarRecipeRepository({
    required Isar isar,
    required RecipeGenerationService generationService,
    RecipeServerService? serverService,
  })  : _isar = isar, // ignore: prefer_initializing_formals
        _generation = generationService,
        _server = serverService;

  final Isar _isar;
  final RecipeGenerationService _generation;
  final RecipeServerService? _server;

  @override
  Future<Result<Recipe, AppError>> generateFromStock(
    List<StockItem> items, {
    String? recipeType,
    String? difficulty,
    int servings = 2,
  }) async {
    final result = await _generation.generateRecipe(
      items: items,
      recipeType: recipeType,
      difficulty: difficulty,
      servings: servings,
    );
    final recipe = result.valueOrNull;
    if (recipe != null) {
      await saveToCache(recipe);
      await _server?.cacheRecipe(recipe);
    }
    return result;
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

  @override
  Future<Result<Recipe, AppError>> generateByName(
    String dishName, {
    int servings = 2,
  }) async {
    // 1. 로컬 캐시 조회
    try {
      final cached = await _isar.isarCachedRecipes
          .where()
          .titleEqualTo(dishName)
          .findFirst();
      if (cached != null) {
        final recipe = _toDomain(cached);
        if (recipe != null) return Result.success(recipe);
      }
    } catch (_) {}

    // 2. 서버 큐레이션 레시피 조회
    // 지역 변수로 받아야 Dart null-promotion이 작동한다 (클래스 필드는 미지원).
    final server = _server;
    if (server != null) {
      final serverResult = await server.fetchByName(dishName);
      if (serverResult != null) {
        final recipe = serverResult.valueOrNull;
        if (recipe != null) {
          await saveToCache(recipe);
          return serverResult;
        }
      }
    }

    // 3. AI 생성 폴백
    final result = await _generation.generateByDishName(
      dishName,
      servings: servings,
    );
    final recipe = result.valueOrNull;
    if (recipe != null) {
      await saveToCache(recipe);
      await server?.cacheRecipe(recipe); // 서버 캐시 write-back (fire-and-forget)
    }
    return result;
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
