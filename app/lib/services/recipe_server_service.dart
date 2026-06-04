import 'package:dio/dio.dart';
import 'package:whipup/core/constants/app_constants.dart';
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/services/mock_recipe_data.dart';

/// 레시피 서버 서비스 추상 인터페이스.
///
/// 캐싱 레이어: Local(Isar) → Server → AI(Gemini)
/// `null` 반환 시 다음 레이어(AI)로 폴백한다.
abstract class RecipeServerService {
  Future<Result<Recipe, AppError>?> fetchByName(String dishName);
}

// ─── 실 백엔드 클라이언트 ──────────────────────────────────────────────────────

/// WhipUp FastAPI 백엔드 클라이언트.
///
/// 엔드포인트: GET /v1/recipes/by-name?q={dishName}
/// 응답 스키마: Recipe.fromJson 과 동일한 camelCase JSON
class WhipupRecipeApiClient implements RecipeServerService {
  static final _baseUrl = '${AppConstants.baseUrl}/v1';

  const WhipupRecipeApiClient(this._dio);
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
}
