import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:whipup/core/constants/app_constants.dart';
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/services/mock_recipe_data.dart';

/// 레시피 서버 서비스 추상 인터페이스.
///
/// 캐싱 레이어: Local(Isar) → Server → AI(Gemini)
/// 각 메서드가 `null` 또는 빈 결과를 반환하면 다음 레이어로 폴백한다.
abstract class RecipeServerService {
  Future<Result<Recipe, AppError>?> fetchByName(String dishName);
  Future<Recipe?> findSimilar(List<String> ingredients);
  Future<void> cacheRecipe(Recipe recipe, {List<String> ingredients = const []});
  Future<bool> updateRecipe(Recipe recipe);
}

/// Dio 인스턴스 생성.
///
/// debug 빌드에서만 자체 서버 인증서 미스매치를 허용한다.
/// release 빌드에서는 TLS 검증을 정상 수행한다.
Dio _buildServerDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );
  if (kDebugMode) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () =>
        HttpClient()..badCertificateCallback = (cert, host, port) => true;
  }
  return dio;
}

// ─── 실 백엔드 클라이언트 ──────────────────────────────────────────────────────

/// WhipUp FastAPI 백엔드 클라이언트.
///
/// 엔드포인트: GET /v1/recipes/by-name?q={dishName}
/// 응답 스키마: Recipe.fromJson 과 동일한 camelCase JSON
class WhipupRecipeApiClient implements RecipeServerService {
  static final _baseUrl = '${AppConstants.baseUrl}/v1';

  WhipupRecipeApiClient([Dio? dio]) : _dio = dio ?? _buildServerDio();
  final Dio _dio;

  @override
  Future<Result<Recipe, AppError>?> fetchByName(String dishName) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/recipes/by-name',
        queryParameters: {'q': dishName},
      );
      if (response.statusCode == 200 && response.data != null) {
        final recipe = Recipe.fromJson(response.data as Map<String, dynamic>);
        return Result.success(recipe);
      }
      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Recipe?> findSimilar(List<String> ingredients) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/recipes/similar',
        data: {'ingredients': ingredients, 'limit': 1, 'threshold': 0.85},
      );
      final list = response.data as List<dynamic>?;
      if (list == null || list.isEmpty) return null;
      return Recipe.fromJson(list.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheRecipe(
    Recipe recipe, {
    List<String> ingredients = const [],
  }) async {
    try {
      await _dio.post(
        '$_baseUrl/recipes',
        data: {
          'recipe_data': recipe.toJson(),
          'ingredients': ingredients,
        },
      );
    } catch (_) {
      // 서버 캐시 실패는 무시 — 로컬 캐시가 primary
    }
  }

  @override
  Future<bool> updateRecipe(Recipe recipe) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/recipes',
        data: {
          'recipe_data': recipe.toJson(),
          'ingredients': recipe.ingredients.map((i) => i.name).toList(),
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}

// ─── 개발용 Mock 서버 ──────────────────────────────────────────────────────────

/// 번들 레시피 데이터를 서버처럼 제공하는 Mock 구현체.
///
/// 실제 백엔드 없이 25가지 한국 대표 요리 레시피를 즉시 반환한다.
/// 운영 배포 시 [WhipupRecipeApiClient]로 교체한다.
class MockRecipeServerService implements RecipeServerService {
  const MockRecipeServerService();

  @override
  Future<Result<Recipe, AppError>?> fetchByName(String dishName) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final data = MockRecipeData.findByName(dishName);
    if (data == null) return null;
    try {
      return Result.success(Recipe.fromJson(data));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Recipe?> findSimilar(List<String> ingredients) async => null;

  @override
  Future<void> cacheRecipe(
    Recipe recipe, {
    List<String> ingredients = const [],
  }) async {}

  @override
  Future<bool> updateRecipe(Recipe recipe) async => true;
}
