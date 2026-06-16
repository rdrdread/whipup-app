import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/providers/isar_provider.dart';
import 'package:whipup/repositories/recipe_repository.dart'; // RecipeHistoryEntry 포함
import 'package:whipup/repositories/impl/isar_recipe_repository.dart';
import 'package:whipup/services/gemini_service.dart';
import 'package:whipup/services/prompt_builder.dart';
import 'package:whipup/services/recipe_generation_service.dart';
import 'package:whipup/services/recipe_server_service.dart';

part 'recipe_providers.g.dart';

// ─── 인프라 Provider ──────────────────────────────────────────────────────────

/// GeminiService Provider.
@riverpod
GeminiService geminiService(Ref ref) {
  return GeminiService(
    dio: Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
    storage: const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
}

/// Gemini API 키 설정 여부.
@riverpod
Future<bool> geminiApiKeyStatus(Ref ref) async {
  return ref.watch(geminiServiceProvider).hasApiKey();
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
  );
}

/// RecipeServerService Provider.
@riverpod
RecipeServerService recipeServerService(Ref ref) => WhipupRecipeApiClient();

/// RecipeRepository Provider (keepAlive).
@Riverpod(keepAlive: true)
Future<RecipeRepository> recipeRepository(Ref ref) async {
  final isar = await ref.watch(isarDbProvider.future);
  final generation = ref.watch(recipeGenerationServiceProvider);
  final server = ref.watch(recipeServerServiceProvider);
  return IsarRecipeRepository(
    isar: isar,
    generationService: generation,
    serverService: server,
  );
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
/// keepAlive: 다른 탭으로 이동했다가 돌아와도 결과가 유지된다.
@Riverpod(keepAlive: true)
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

/// 완료된 요리 히스토리 목록 (최신순).
@riverpod
Future<List<RecipeHistoryEntry>> cookingHistory(Ref ref) async {
  final repository = await ref.watch(recipeRepositoryProvider.future);
  final result = await repository.getHistory();
  return result.valueOrNull ?? [];
}

