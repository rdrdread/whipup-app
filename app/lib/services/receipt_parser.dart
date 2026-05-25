import 'package:whipup/models/ocr_result.dart';
import 'package:whipup/models/stock_category.dart';

/// 영수증 텍스트 파싱 서비스.
///
/// OCR로 추출된 영수증 텍스트를 분석하여
/// 재료 후보 목록으로 변환한다.
///
/// Phase 1.2 구현. 기본적인 패턴 매칭 기반이며,
/// Phase 2.0+에서 Gemini Vision API로 고도화 예정.
class ReceiptParser {
  const ReceiptParser();

  /// 영수증 텍스트에서 재료 후보를 파싱한다.
  OcrResult parse(String rawText) {
    final lines = rawText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final candidates = <OcrIngredientCandidate>[];

    for (final line in lines) {
      final trimmed = line.trim();

      // 숫자만 있는 줄, 날짜, 가격 등 제외
      if (_shouldSkipLine(trimmed)) continue;

      final candidate = _parseLine(trimmed);
      if (candidate != null) {
        candidates.add(candidate);
      }
    }

    return OcrResult(candidates: candidates, rawText: rawText);
  }

  /// 건너뛸 라인인지 확인한다.
  bool _shouldSkipLine(String line) {
    // 3글자 미만 제외
    if (line.length < 2) return true;
    // 순수 숫자/특수문자 제외
    if (RegExp(r'^[\d\s\-\.\,\*\/\(\)\[\]]+$').hasMatch(line)) return true;
    // 영수증 헤더/푸터 키워드 제외
    final skipKeywords = ['합계', '총계', '부가세', 'VAT', '카드', '현금', '거스름', '영수증', '주소', '전화', '사업자', '대표자', '주문'];
    for (final keyword in skipKeywords) {
      if (line.contains(keyword)) return true;
    }
    return false;
  }

  /// 라인에서 재료 후보를 추출한다.
  OcrIngredientCandidate? _parseLine(String line) {
    // 가격 패턴 제거 (숫자+원)
    final cleaned = line
        .replaceAll(RegExp(r'\d+,?\d*원'), '')
        .replaceAll(RegExp(r'\d+,?\d*'), '')
        .trim();

    if (cleaned.length < 2) return null;

    // 수량 패턴 추출 (예: "500g", "2개", "1kg")
    final quantityMatch =
        RegExp(r'(\d+(?:\.\d+)?)\s*(g|kg|ml|L|개|봉|팩|병|캔|장|묶음)')
            .firstMatch(line);
    final quantity = quantityMatch?.group(1);
    final unit = quantityMatch?.group(2);

    // 재료명 정제
    final name = cleaned
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\가-힣a-zA-Z\s]'), '')
        .trim();

    if (name.length < 2) return null;

    return OcrIngredientCandidate(
      name: name,
      quantity: quantity,
      unit: unit,
      category: _inferCategory(name),
    );
  }

  /// 재료명으로부터 카테고리를 추론한다.
  StockCategory _inferCategory(String name) {
    final n = name;
    if (_containsAny(n, ['삼겹', '목살', '등심', '갈비', '닭', '소고기', '돼지', '오리'])) {
      return StockCategory.meat;
    }
    if (_containsAny(n, ['고등어', '연어', '참치', '오징어', '새우', '조개', '굴', '생선'])) {
      return StockCategory.seafood;
    }
    if (_containsAny(n, ['배추', '양파', '마늘', '대파', '당근', '감자', '무', '채소', '시금치', '상추'])) {
      return StockCategory.vegetable;
    }
    if (_containsAny(n, ['사과', '배', '딸기', '수박', '과일', '오렌지', '포도'])) {
      return StockCategory.fruit;
    }
    if (_containsAny(n, ['우유', '치즈', '요거트', '버터', '크림'])) {
      return StockCategory.dairy;
    }
    if (_containsAny(n, ['쌀', '밀가루', '라면', '파스타', '빵', '면', '곡물'])) {
      return StockCategory.grain;
    }
    if (_containsAny(n, ['간장', '된장', '고추장', '소금', '식용유', '참기름', '양념', '소스'])) {
      return StockCategory.seasoning;
    }
    return StockCategory.other;
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
}
