import 'package:whipup/models/stock_category.dart';
import 'package:whipup/models/voice_input_result.dart';

/// 음성 인식 텍스트 파싱 서비스.
///
/// 음성으로 인식된 자연어 텍스트를 분석하여
/// 재료 후보 목록으로 변환한다.
///
/// 예: "양파 두 개랑 돼지고기 오백 그램이요" →
///   [VoiceIngredientCandidate(name: '양파', quantity: '2', unit: '개'), ...]
class VoiceParser {
  const VoiceParser();

  /// 음성 인식 텍스트를 재료 후보 목록으로 파싱한다.
  VoiceInputResult parse(String transcript) {
    final candidates = <VoiceIngredientCandidate>[];
    final segments = _splitSegments(transcript);

    for (final segment in segments) {
      final candidate = _parseSegment(segment.trim());
      if (candidate != null) {
        candidates.add(candidate);
      }
    }

    return VoiceInputResult(
      transcript: transcript,
      candidates: candidates,
    );
  }

  /// 텍스트를 재료 단위로 분리한다.
  List<String> _splitSegments(String text) {
    // 연결어로 분리 ("랑", "이랑", "하고", "그리고", "과", "와")
    return text
        .split(RegExp(r'(?:이랑|랑|하고|그리고|,|，|과\s|와\s)'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  /// 하나의 세그먼트를 파싱하여 재료 후보를 반환한다.
  VoiceIngredientCandidate? _parseSegment(String segment) {
    if (segment.length < 2) return null;

    String? quantity;
    String? unit;
    String name = segment;

    // 한국어 수량 패턴 매칭
    // 예: "오백 그램", "두 개", "한 봉지"
    final koreanNumberMatch = _matchKoreanQuantity(segment);
    if (koreanNumberMatch != null) {
      quantity = koreanNumberMatch['quantity'];
      unit = koreanNumberMatch['unit'];
      name = segment
          .replaceFirst(koreanNumberMatch['original']!, '')
          .trim();
    }

    // 아라비아 숫자 패턴 매칭
    // 예: "500g", "2개", "1kg"
    final numericMatch =
        RegExp(r'(\d+(?:\.\d+)?)\s*(g|kg|ml|L|개|봉|팩|병|캔|장|묶음)')
            .firstMatch(segment);
    if (numericMatch != null && koreanNumberMatch == null) {
      quantity = numericMatch.group(1);
      unit = numericMatch.group(2);
      name = segment
          .replaceFirst(numericMatch.group(0)!, '')
          .trim();
    }

    // 재료명 정제 (불필요한 어미 제거)
    name = _cleanName(name);

    if (name.length < 2) return null;

    return VoiceIngredientCandidate(
      name: name,
      quantity: quantity,
      unit: unit,
      category: _inferCategory(name),
    );
  }

  /// 한국어 수량 표현을 파싱한다.
  Map<String, String>? _matchKoreanQuantity(String text) {
    final koreanNumbers = {
      '한': '1', '하나': '1', '두': '2', '둘': '2', '세': '3', '셋': '3',
      '네': '4', '넷': '4', '다섯': '5', '여섯': '6', '일곱': '7',
      '여덟': '8', '아홉': '9', '열': '10',
      '백': '100', '이백': '200', '삼백': '300', '사백': '400', '오백': '500',
      '육백': '600', '칠백': '700', '팔백': '800', '구백': '900', '천': '1000',
    };

    final units = ['그램', '킬로그램', '밀리리터', '리터', '개', '봉지', '팩', '병', '캔', '장', '묶음'];
    final unitMap = {
      '그램': 'g', '킬로그램': 'kg', '밀리리터': 'ml', '리터': 'L',
      '개': '개', '봉지': '봉', '팩': '팩', '병': '병', '캔': '캔',
      '장': '장', '묶음': '묶음',
    };

    for (final numEntry in koreanNumbers.entries) {
      for (final unit in units) {
        final pattern = '${numEntry.key} $unit';
        if (text.contains(pattern)) {
          return {
            'quantity': numEntry.value,
            'unit': unitMap[unit] ?? unit,
            'original': pattern,
          };
        }
        // 공백 없는 패턴도 확인
        final patternNoSpace = '${numEntry.key}$unit';
        if (text.contains(patternNoSpace)) {
          return {
            'quantity': numEntry.value,
            'unit': unitMap[unit] ?? unit,
            'original': patternNoSpace,
          };
        }
      }
    }

    return null;
  }

  /// 재료명에서 불필요한 어미, 조사를 제거한다.
  String _cleanName(String name) {
    return name
        .replaceAll(RegExp(r'(?:이요|요|이에요|에요|입니다|이랑|랑|하고|이랑|이나|나)\s*$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 재료명으로부터 카테고리를 추론한다.
  StockCategory _inferCategory(String name) {
    if (_containsAny(name, ['삼겹', '목살', '등심', '갈비', '닭', '소고기', '돼지', '오리', '육류', '고기'])) {
      return StockCategory.meat;
    }
    if (_containsAny(name, ['고등어', '연어', '참치', '오징어', '새우', '조개', '굴', '생선', '해산물'])) {
      return StockCategory.seafood;
    }
    if (_containsAny(name, ['배추', '양파', '마늘', '대파', '당근', '감자', '무', '채소', '시금치', '상추', '버섯'])) {
      return StockCategory.vegetable;
    }
    if (_containsAny(name, ['사과', '배', '딸기', '수박', '과일', '오렌지', '포도', '바나나'])) {
      return StockCategory.fruit;
    }
    if (_containsAny(name, ['우유', '치즈', '요거트', '버터', '크림', '유제품'])) {
      return StockCategory.dairy;
    }
    if (_containsAny(name, ['쌀', '밀가루', '라면', '파스타', '빵', '면', '곡물', '국수'])) {
      return StockCategory.grain;
    }
    if (_containsAny(name, ['간장', '된장', '고추장', '소금', '식용유', '참기름', '양념', '소스', '식초'])) {
      return StockCategory.seasoning;
    }
    return StockCategory.other;
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
}
