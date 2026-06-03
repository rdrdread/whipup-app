/// 재료 수량 문자열을 인분 수에 맞게 스케일링하는 유틸리티.
///
/// Flutter 의존 없는 순수 Dart 함수.
/// 호출 레이어 제한 없음 (core 공유 유틸).
///
/// 스케일링 전략:
/// - 주재료(채소, 육류, 곡물 등): 선형 비례 (exponent = 1.0)
/// - 조미료/향신료(소금, 간장, 마늘 등): 멱함수 비선형 (exponent = 0.7)
///   근거: 1인분→2인분 시 소금을 2배 넣으면 과도하게 짜짐.
///         경험칙 power-law: scaled = base × (target/base)^0.7
///
/// 표시 형식: 0.5 단위로 반올림 후 .5는 "N단위 반"으로 표기.
///   예) 4.6큰술 → "4큰술 반", 3.1개 → "3개", 4.9큰술 → "5큰술"
library;

import 'dart:math' as math;

/// 재료 수량 + 단위를 인분에 맞게 스케일링 후 완성된 표시 문자열 반환.
///
/// [raw] ingredient.amount 문자열
/// [base] 기준 인분 수
/// [target] 목표 인분 수
/// [unit] 단위 문자열 (예: "큰술", "개", "g")
/// [ingredientName] 재료명 — 조미료 분류에 사용
///
/// 0.5 단위로 반올림하여:
/// - 정수 → "3큰술"
/// - .5  → "3큰술 반" (whole=0이면 "반 큰술")
/// - 파싱 불가("약간" 등) → "약간큰술" 형태가 되지 않도록 원본+단위 그대로
String scaleAndFormat(
  String raw,
  int base,
  int target,
  String unit, {
  String ingredientName = '',
}) {
  final scaled = _scaleToDouble(raw, base, target, ingredientName: ingredientName);
  if (scaled == null) return '$raw$unit'; // 약간, 적당량 등

  // 0.5 단위로 반올림
  final rounded = (scaled * 2).round() / 2;
  return _formatWithUnit(rounded, unit);
}

/// 기존 호환용: unit 없이 수량 문자열만 반환.
///
/// 새 코드는 [scaleAndFormat]을 사용하고, 이 함수는 단위 없는 맥락에서만 사용한다.
String scaleAmount(
  String raw,
  int base,
  int target, {
  String ingredientName = '',
}) {
  final scaled = _scaleToDouble(raw, base, target, ingredientName: ingredientName);
  if (scaled == null) return raw;

  // 0.5 단위로 반올림
  final rounded = (scaled * 2).round() / 2;
  final whole = rounded.truncate();
  final isHalf = (rounded - whole) >= 0.25;

  if (whole == 0 && isHalf) return '0.5';
  if (isHalf) return '$whole 반';
  return whole.toString();
}

// ─────────────────────────────── internal ───────────────────────────────────

/// 파싱 + 스케일링 → double 반환. 파싱 불가면 null.
double? _scaleToDouble(
  String raw,
  int base,
  int target, {
  String ingredientName = '',
}) {
  if (base <= 0 || target <= 0) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final exponent = _scalingExponent(ingredientName);
  final ratio = target / base;
  final factor = math.pow(ratio, exponent).toDouble();

  // 1) 순수 숫자
  final d = double.tryParse(trimmed);
  if (d != null) return base == target ? d : d * factor;

  // 2) 단순 분수 "a/b"
  final fracMatch = RegExp(r'^(\d+)/(\d+)$').firstMatch(trimmed);
  if (fracMatch != null) {
    final n = int.parse(fracMatch.group(1)!);
    final den = int.parse(fracMatch.group(2)!);
    if (den == 0) return null;
    final val = n / den;
    return base == target ? val : val * factor;
  }

  // 3) 대분수 "a b/c"
  final mixedMatch = RegExp(r'^(\d+)\s+(\d+)/(\d+)$').firstMatch(trimmed);
  if (mixedMatch != null) {
    final whole = int.parse(mixedMatch.group(1)!);
    final n = int.parse(mixedMatch.group(2)!);
    final den = int.parse(mixedMatch.group(3)!);
    if (den == 0) return null;
    final val = whole + n / den;
    return base == target ? val : val * factor;
  }

  // 4) 파싱 불가 (약간, 적당량, …)
  return null;
}

/// 스케일된 double과 단위를 "N단위" 또는 "N단위 반" 형식으로 조합.
String _formatWithUnit(double rounded, String unit) {
  final whole = rounded.truncate();
  final isHalf = (rounded - whole) >= 0.25;

  if (whole == 0 && isHalf) {
    // 0.5: "반 큰술" 형태
    return unit.isEmpty ? '0.5' : '반 $unit';
  }
  if (isHalf) {
    // N.5: "N큰술 반" 형태
    return unit.isEmpty ? '$whole 반' : '$whole$unit 반';
  }
  // 정수: "N큰술"
  return '$whole$unit';
}

/// 재료명에 따른 스케일링 지수 결정.
double _scalingExponent(String name) {
  if (name.isEmpty) return 1.0;
  final lower = name.toLowerCase();
  for (final keyword in _condimentKeywords) {
    if (lower.contains(keyword)) return 0.7;
  }
  return 1.0;
}

/// 조미료·향신료·기름류 키워드 목록.
const List<String> _condimentKeywords = [
  // 염분류
  '소금', '간장', '액젓', '멸치액젓', '까나리액젓', '새우젓', '된장', '쌈장',
  // 발효·소스류
  '고추장', '굴소스', '피시소스', '우스터', '핫소스', '타바스코',
  '케첩', '마요네즈', '머스터드',
  // 가루·향신료
  '고춧가루', '고추가루', '후추', '후춧가루', '파프리카', '강황', '커민',
  '계피', '시나몬', '팔각', '정향', '산초', '카레가루', '카레',
  // 방향 채소 (소량 사용)
  '마늘', '생강', '청양고추', '홍고추', '할라피뇨', '와사비', '겨자',
  // 당류
  '설탕', '흑설탕', '황설탕', '올리고당', '꿀', '물엿', '매실청', '조청',
  '아가베', '스테비아',
  // 산미류
  '식초', '레몬즙', '라임즙', '유자청',
  // 기름류
  '참기름', '들기름', '올리브오일', '식용유', '참깨', '깨소금',
  '코코넛오일', '아보카도오일',
  // 알코올류 (소량)
  '청주', '미림', '맛술',
  // 기타 조미료
  '다시다', '미원', 'msg', '치킨스톡', '두반장',
];
