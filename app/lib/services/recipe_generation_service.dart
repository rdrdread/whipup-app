import 'dart:convert';
import 'dart:math';
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/models/recipe_type.dart';
import 'package:whipup/models/stock_item.dart';
import 'package:whipup/services/gemini_service.dart';
import 'package:whipup/services/prompt_builder.dart';

/// 레시피 생성 서비스.
///
/// AI(Gemini)를 통해 레시피를 생성하고 파싱만 담당한다.
/// 캐시 저장은 [IsarRecipeRepository]가 담당하여 순환 의존을 방지한다.
///
/// 데이터 흐름: `docs/core/product_map.md §6.1`
class RecipeGenerationService {
  RecipeGenerationService({
    required GeminiService geminiService,
    required PromptBuilder promptBuilder,
  })  : _gemini = geminiService,
        _promptBuilder = promptBuilder;

  final GeminiService _gemini;
  final PromptBuilder _promptBuilder;

  /// 재고 재료 기반 레시피를 생성하거나 캐시에서 반환한다.
  Future<Result<Recipe, AppError>> generateRecipe({
    required List<StockItem> items,
    String? recipeType,
    String? difficulty,
    int servings = 2,
  }) async {
    // 1순위: 로컬 캐시 (TODO: 유사 재료 매칭 - Phase 2.1 벡터 캐시)
    // 현재는 캐시 미사용하고 항상 AI 생성 (사용자 경험 일관성)

    // 2순위: AI 생성
    final prompt = _promptBuilder.buildRecipePrompt(
      items: items,
      recipeType: recipeType,
      difficulty: difficulty,
      servings: servings,
    );

    final aiResult = await _gemini.generateContent(prompt);

    return aiResult.when(
      success: (jsonText) => _parseRecipe(jsonText),
      failure: (error) => Result.failure(error),
    );
  }

  /// JSON 텍스트를 Recipe로 파싱한다. 캐시 저장은 호출자가 담당한다.
  Future<Result<Recipe, AppError>> _parseRecipe(String jsonText) async {
    try {
      // 마크다운 코드 블록 제거
      var cleanJson = jsonText.trim();
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson
            .replaceAll(RegExp(r'^```[a-zA-Z]*\n?'), '')
            .replaceAll(RegExp(r'\n?```$'), '')
            .trim();
      }

      final jsonMap = json.decode(cleanJson) as Map<String, dynamic>;

      // UUID가 없으면 자동 생성
      if (!jsonMap.containsKey('id') ||
          (jsonMap['id'] as String?)?.isEmpty == true) {
        jsonMap['id'] = _generateUuid();
      }

      // snake_case → camelCase 변환
      final normalized = _normalizeJson(jsonMap);
      final recipe = Recipe.fromJson(normalized);

      return Result.success(recipe);
    } on FormatException catch (e) {
      return Result.failure(AppError.parsing('레시피 JSON 파싱 실패: $e'));
    } catch (e) {
      return Result.failure(AppError.parsing('레시피 변환 실패: $e'));
    }
  }

  /// Gemini 응답 JSON(snake_case)을 Freezed 모델(camelCase)로 변환한다.
  Map<String, dynamic> _normalizeJson(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'title': json['title'],
      'description': json['description'],
      'recipeType': _mapRecipeType(json['recipe_type'] as String? ?? 'main'),
      'servings': json['servings'] ?? 2,
      'cookingTimeMinutes': json['cooking_time_minutes'] ?? 30,
      'difficulty': _mapDifficulty(json['difficulty'] as String? ?? 'medium'),
      'ingredients': (json['ingredients'] as List<dynamic>? ?? [])
          .map(_normalizeIngredient)
          .toList(),
      'steps': (json['steps'] as List<dynamic>? ?? [])
          .map(_normalizeStep)
          .toList(),
      'tags': (json['tags'] as List<dynamic>? ?? []).cast<String>(),
      'flavorProfile':
          _normalizeFlavorProfile(json['flavor_profile'] as Map<String, dynamic>? ?? {}),
      'scienceNote': json['science_note'],
      'sources': (json['sources'] as List<dynamic>? ?? []).cast<String>(),
    };
  }

  Map<String, dynamic> _normalizeIngredient(dynamic item) {
    final m = item as Map<String, dynamic>;
    return {
      'name': m['name'] ?? '',
      'amount': (m['amount'] ?? '').toString(),
      'unit': m['unit'] ?? '',
      'isOptional': m['is_optional'] ?? false,
    };
  }

  Map<String, dynamic> _normalizeStep(dynamic item) {
    final m = item as Map<String, dynamic>;
    return {
      'stepNumber': m['step_number'] ?? 1,
      'phase': _mapCookingPhase(m['phase'] as String? ?? 'prep'),
      'description': m['description'] ?? '',
      'durationSeconds': m['duration_seconds'],
      'tip': m['tip'],
      'mediaUrl': m['media_url'],
      'mediaType': m['media_type'],
    };
  }

  Map<String, dynamic> _normalizeFlavorProfile(Map<String, dynamic> m) {
    return {
      'umami': (m['umami'] as num?)?.toInt() ?? 0,
      'sweet': (m['sweet'] as num?)?.toInt() ?? 0,
      'sour': (m['sour'] as num?)?.toInt() ?? 0,
      'salty': (m['salty'] as num?)?.toInt() ?? 0,
      'spicy': (m['spicy'] as num?)?.toInt() ?? 0,
    };
  }

  String _mapRecipeType(String value) {
    for (final t in RecipeType.values) {
      if (t.name == value) return value;
    }
    return 'main';
  }

  String _mapDifficulty(String value) {
    for (final d in RecipeDifficulty.values) {
      if (d.name == value) return value;
    }
    return 'medium';
  }

  String _mapCookingPhase(String value) {
    for (final p in CookingPhase.values) {
      if (p.name == value) return value;
    }
    return 'prep';
  }

  /// UUID v4를 생성한다 (외부 패키지 없이 구현).
  String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
