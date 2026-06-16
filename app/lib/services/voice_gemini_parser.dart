import 'dart:convert';

import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';
import 'package:whipup/models/stock_category.dart';
import 'package:whipup/models/voice_input_result.dart';
import 'package:whipup/services/gemini_service.dart';
import 'package:whipup/services/prompt_builder.dart';
import 'package:whipup/services/sub_category_service.dart';

/// Gemini 기반 음성 텍스트 → 재료 목록 파서.
///
/// 음성 인식 텍스트를 Gemini에 전달하고 구조화된 재료 후보 목록을 반환한다.
/// 보관 위치와 유통기한은 카테고리 기반으로 로컬에서 추론하여 API 응답 속도를 개선한다.
class VoiceGeminiParser {
  const VoiceGeminiParser({
    required GeminiService geminiService,
    required PromptBuilder promptBuilder,
  })  : _geminiService = geminiService,
        _promptBuilder = promptBuilder;

  final GeminiService _geminiService;
  final PromptBuilder _promptBuilder;

  /// 음성 텍스트를 파싱하여 재료 후보 목록을 반환한다.
  Future<Result<VoiceInputResult, AppError>> parse(String transcript) async {
    final prompt = _promptBuilder.buildVoiceParsingPrompt(transcript);
    // generateText 사용: responseMimeType 스키마 제약 없이 순수 JSON 배열 반환
    final result = await _geminiService.generateText(prompt);

    return result.when(
      success: (json) {
        try {
          final candidates = _parseCandidates(json);
          if (candidates.isEmpty) {
            return const Result.failure(
              AppError.parsing('인식된 재료가 없습니다. 다시 말씀해 주세요.'),
            );
          }
          return Result.success(VoiceInputResult(
            transcript: transcript,
            candidates: candidates,
          ));
        } catch (e) {
          return Result.failure(
            AppError.parsing('재료 목록 파싱 실패: $e'),
          );
        }
      },
      failure: (error) => Result.failure(error),
    );
  }

  List<VoiceIngredientCandidate> _parseCandidates(String raw) {
    var cleaned = raw.trim();
    // 마크다운 코드 블록 제거
    cleaned = cleaned.replaceAll(RegExp(r'```(?:json)?'), '').trim();
    // 앞뒤 불필요한 텍스트 제거 (배열만 추출)
    final arrayStart = cleaned.indexOf('[');
    final arrayEnd = cleaned.lastIndexOf(']');
    if (arrayStart != -1 && arrayEnd != -1) {
      cleaned = cleaned.substring(arrayStart, arrayEnd + 1);
    }

    final List<dynamic> items = jsonDecode(cleaned) as List<dynamic>;

    return items
        .whereType<Map<String, dynamic>>()
        .map(_toCandidate)
        .where((c) => c.name.trim().isNotEmpty)
        .toList();
  }

  VoiceIngredientCandidate _toCandidate(Map<String, dynamic> map) {
    final category = _parseCategory(map['category'] as String? ?? '');
    final subCategory = _normalizeSubCategory(map['sub_category']);

    final expiryDays = SubCategoryService.getDefaultExpiryDays(
      category,
      subCategory: subCategory,
    );
    final expiryDate = DateTime.now().add(Duration(days: expiryDays > 0 ? expiryDays : 7));

    final unit = map['unit'] as String?;
    final defaultUnit = SubCategoryService.getDefaultUnit(
      category,
      subCategory: subCategory,
    );

    return VoiceIngredientCandidate(
      name: (map['name'] as String? ?? '').trim(),
      quantity: _normalizeQuantity(map['quantity']),
      unit: (unit?.isNotEmpty == true) ? unit : defaultUnit,
      category: category,
      subCategory: subCategory,
      storageLocation: _inferStorageLocation(category),
      expiryDate: expiryDate,
    );
  }

  String? _normalizeSubCategory(dynamic value) {
    if (value == null || value.toString().toLowerCase() == 'null') return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  String _normalizeQuantity(dynamic value) {
    if (value == null) return '1';
    final str = value.toString().trim();
    return str.isEmpty ? '1' : str;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  StockCategory _parseCategory(String value) {
    switch (value.toLowerCase()) {
      case 'meat':
        return StockCategory.meat;
      case 'seafood':
        return StockCategory.seafood;
      case 'vegetable':
        return StockCategory.vegetable;
      case 'fruit':
        return StockCategory.fruit;
      case 'dairy':
        return StockCategory.dairy;
      case 'grain':
        return StockCategory.grain;
      case 'seasoning':
        return StockCategory.seasoning;
      case 'beverage':
        return StockCategory.beverage;
      case 'frozen':
        return StockCategory.frozen;
      default:
        return StockCategory.other;
    }
  }

  /// 카테고리 기반 보관 위치 추론 (로컬).
  ///
  /// grain → pantry, seasoning → drawer, frozen → freezer, 나머지 → fridge.
  StorageLocation _inferStorageLocation(StockCategory category) {
    switch (category) {
      case StockCategory.grain:
        return StorageLocation.pantry;
      case StockCategory.seasoning:
        return StorageLocation.drawer;
      case StockCategory.frozen:
        return StorageLocation.freezer;
      default:
        return StorageLocation.fridge;
    }
  }
}
