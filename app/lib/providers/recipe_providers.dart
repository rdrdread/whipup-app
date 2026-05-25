import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/providers/isar_provider.dart';
import 'package:whipup/repositories/recipe_repository.dart';
import 'package:whipup/repositories/impl/isar_recipe_repository.dart';
import 'package:whipup/services/gemini_service.dart';
import 'package:whipup/services/prompt_builder.dart';
import 'package:whipup/services/recipe_generation_service.dart';

part 'recipe_providers.g.dart';

// ─── 인프라 Provider ──────────────────────────────────────────────────────────

/// GeminiService Provider.
@riverpod
GeminiService geminiService(Ref ref) {
  return GeminiService(
    dio: Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
    storage: const FlutterSecureStorage(),
  );
}

/// PromptBuilder Provider.
@riverpod
PromptBuilder promptBuilder(Ref ref) => const PromptBuilder();

/// RecipeGenerationService Provider.
@riverpod
RecipeGenerationService recipeGenerationService(Ref ref) {
  return RecipeGenerationService(
    geminiService: ref.watch(geminiServiceProvider),
    promptBuilder: ref.watch(promptBuilderProvider),
    recipeRepository: ref.watch(recipeRepositoryProvider).asData?.value ??
        _PlaceholderRecipeRepository(),
  );
}

/// RecipeRepository Provider (keepAlive).
@Riverpod(keepAlive: true)
Future<RecipeRepository> recipeRepository(Ref ref) async {
  final isar = await ref.watch(isarDbProvider.future);
  final generation = ref.watch(recipeGenerationServiceProvider);
  return IsarRecipeRepository(isar: isar, generationService: generation);
}

// ─── 재료 선택 Provider ───────────────────────────────────────────────────────

/// 레시피 요청용 선택된 재료 목록 Notifier.
@riverpod
class SelectedIngredients extends _$SelectedIngredients {
  @override
  List<StockItem> build() => [];

  /// 재료 선택 토글.
  void toggle(StockItem item) {
    if (state.any((i) => i.id == item.id)) {
      state = state.where((i) => i.id != item.id).toList();
    } else {
      state = [...state, item];
    }
  }

  /// 전체 선택.
  void selectAll(List<StockItem> items) {
    state = List.from(items);
  }

  /// 전체 해제.
  void clearAll() {
    state = [];
  }

  /// 특정 아이템이 선택되어 있는지 확인.
  bool isSelected(StockItem item) => state.any((i) => i.id == item.id);
}

// ─── 레시피 옵션 Provider ─────────────────────────────────────────────────────

/// 레시피 생성 옵션 (recipeType, difficulty, servings).
@riverpod
class RecipeOptions extends _$RecipeOptions {
  @override
  RecipeOptionState build() => const RecipeOptionState();

  void setRecipeType(String? type) =>
      state = state.copyWith(recipeType: type);

  void setDifficulty(String? difficulty) =>
      state = state.copyWith(difficulty: difficulty);

  void setServings(int servings) =>
      state = state.copyWith(servings: servings);
}

/// 레시피 생성 옵션 상태.
class RecipeOptionState {
  const RecipeOptionState({
    this.recipeType,
    this.difficulty,
    this.servings = 2,
  });

  final String? recipeType;
  final String? difficulty;
  final int servings;

  RecipeOptionState copyWith({
    String? recipeType,
    String? difficulty,
    int? servings,
    bool clearRecipeType = false,
    bool clearDifficulty = false,
  }) =>
      RecipeOptionState(
        recipeType: clearRecipeType ? null : (recipeType ?? this.recipeType),
        difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
        servings: servings ?? this.servings,
      );
}

// ─── 레시피 생성 Provider ─────────────────────────────────────────────────────

/// AI 레시피 생성 Notifier.
///
/// [generate] 호출 → AI 생성 → 결과 캐시 → UI 갱신
@riverpod
class RecipeGenerator extends _$RecipeGenerator {
  @override
  AsyncValue<Recipe?> build() => const AsyncValue.data(null);

  /// 선택된 재료 기반 레시피 생성.
  Future<void> generate() async {
    final items = ref.read(selectedIngredientsProvider);
    if (items.isEmpty) return;

    final options = ref.read(recipeOptionsProvider);
    final repository = await ref.read(recipeRepositoryProvider.future);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await repository.generateFromStock(
        items,
        recipeType: options.recipeType,
        difficulty: options.difficulty,
        servings: options.servings,
      );
      return result.when(
        success: (recipe) => recipe,
        failure: (error) => throw Exception(error.message),
      );
    });
  }

  /// 생성 결과를 초기화한다.
  void reset() {
    state = const AsyncValue.data(null);
  }
}

// ─── 레시피 캐시 Provider ─────────────────────────────────────────────────────

/// 로컬 캐시 레시피 목록.
@riverpod
Future<List<Recipe>> cachedRecipes(Ref ref) async {
  final repository = await ref.watch(recipeRepositoryProvider.future);
  final result = await repository.getCached();
  return result.valueOrNull ?? [];
}

/// 즐겨찾기 레시피 목록.
@riverpod
Future<List<Recipe>> favoriteRecipes(Ref ref) async {
  final repository = await ref.watch(recipeRepositoryProvider.future);
  final result = await repository.getFavorites();
  return result.valueOrNull ?? [];
}

// ─── Placeholder (초기화 전 임시) ─────────────────────────────────────────────

/// RecipeGenerationService 초기화 전 임시 플레이스홀더.
///
/// recipeRepository가 비동기 초기화 중일 때만 사용.
class _PlaceholderRecipeRepository implements RecipeRepository {
  @override
  Future<Result<Recipe, AppError>> generateFromStock(List<StockItem> items,
          {String? recipeType, String? difficulty, int servings = 2}) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<Recipe>, AppError>> getCached() async =>
      throw UnimplementedError();

  @override
  Future<Result<void, AppError>> saveToCache(Recipe recipe) async =>
      throw UnimplementedError();

  @override
  Future<Result<void, AppError>> toggleFavorite(String recipeId) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<Recipe>, AppError>> getFavorites() async =>
      throw UnimplementedError();

  @override
  Future<Result<Recipe, AppError>> getById(String recipeId) async =>
      throw UnimplementedError();

  @override
  Future<Result<void, AppError>> markCompleted(String recipeId) async =>
      throw UnimplementedError();
}
