import 'package:whipup/models/stock_category.dart';

/// 서브 카테고리 데이터 및 단위 자동 추천 서비스.
///
/// US-6: 서브 카테고리 선택 시 재료명 자동 입력 + 단위 자동 설정.
/// 데이터 정의: `docs/core/product_map.md §3.1`
abstract final class SubCategoryService {
  // ─── 서브 카테고리 맵 ─────────────────────────────────────────────────────

  /// 카테고리별 서브 카테고리 목록.
  static const Map<StockCategory, List<String>> subCategoryMap = {
    StockCategory.meat: ['소고기', '돼지고기', '닭고기', '양고기', '오리고기'],
    StockCategory.seafood: ['생선', '조개류', '갑각류', '오징어/낙지류'],
    StockCategory.vegetable: ['잎채소', '뿌리채소', '열매채소', '줄기채소', '버섯'],
    StockCategory.fruit: ['국산과일', '열대과일', '베리류'],
    StockCategory.dairy: ['우유/크림', '치즈', '버터/마가린', '요거트/발효유', '달걀'],
    StockCategory.grain: ['쌀/잡곡', '밀가루/전분', '면류', '빵/떡'],
    StockCategory.seasoning: ['간장/된장/고추장', '소금/설탕/식초', '오일류', '소스류', '향신료'],
    StockCategory.beverage: ['물/탄산', '주스/음료', '유제품음료', '주류'],
    StockCategory.frozen: ['냉동육류', '냉동해산물', '냉동채소', '냉동가공식품'],
    StockCategory.other: [],
  };

  /// 서브 카테고리별 부위/종류 목록.
  static const Map<String, List<String>> partMap = {
    // 육류
    '소고기': ['등심', '안심', '갈비', '채끝', '설도', '사태', '우삼겹', '꽃등심'],
    '돼지고기': ['목살', '삼겹살', '갈비', '안심', '등심', '앞다리', '뒷다리'],
    '닭고기': ['가슴살', '다리', '통닭', '날개', '안심'],
    '양고기': ['갈비', '안심', '어깨살'],
    '오리고기': ['가슴살', '다리'],
    // 해산물
    '생선': ['고등어', '연어', '참치', '광어', '조기', '갈치', '꽁치'],
    '조개류': ['바지락', '홍합', '전복', '굴', '가리비'],
    '갑각류': ['새우', '꽃게', '랍스터', '킹크랩'],
    '오징어/낙지류': ['오징어', '낙지', '문어', '쭈꾸미'],
    // 채소
    '잎채소': ['배추', '시금치', '상추', '깻잎', '케일', '열무', '미나리'],
    '뿌리채소': ['당근', '감자', '무', '양파', '고구마', '비트', '생강', '마늘'],
    '열매채소': ['오이', '호박', '토마토', '파프리카', '가지', '고추'],
    '줄기채소': ['대파', '아스파라거스', '샐러리', '브로콜리', '콜리플라워'],
    '버섯': ['표고버섯', '느타리버섯', '새송이버섯', '팽이버섯', '양송이버섯'],
    // 과일
    '국산과일': ['사과', '배', '감', '딸기', '포도', '복숭아', '귤'],
    '열대과일': ['바나나', '망고', '파인애플', '키위', '아보카도'],
    '베리류': ['블루베리', '딸기', '라즈베리', '체리'],
    // 유제품
    '우유/크림': ['우유', '생크림', '두유'],
    '치즈': ['모차렐라', '체다', '파마산', '크림치즈', '슬라이스치즈'],
    '버터/마가린': ['무염버터', '가염버터', '마가린'],
    '요거트/발효유': ['플레인요거트', '그릭요거트', '요구르트'],
    '달걀': ['계란', '메추리알'],
    // 곡류
    '쌀/잡곡': ['백미', '현미', '찹쌀', '혼합잡곡', '오트밀'],
    '밀가루/전분': ['중력분', '강력분', '박력분', '옥수수전분', '감자전분'],
    '면류': ['소면', '중면', '우동면', '파스타', '당면'],
    '빵/떡': ['식빵', '바게트', '백설기', '떡볶이떡'],
  };

  // ─── 기본 단위 맵 ─────────────────────────────────────────────────────────

  /// 카테고리별 기본 단위.
  static const Map<StockCategory, String> categoryDefaultUnit = {
    StockCategory.meat: 'g',
    StockCategory.seafood: 'g',
    StockCategory.vegetable: 'g',
    StockCategory.fruit: '개',
    StockCategory.dairy: 'g',
    StockCategory.grain: 'g',
    StockCategory.seasoning: 'g',
    StockCategory.beverage: 'ml',
    StockCategory.frozen: 'g',
    StockCategory.other: '개',
  };

  /// 서브 카테고리별 기본 단위 (카테고리 기본값 오버라이드).
  static const Map<String, String> subCategoryDefaultUnit = {
    // 채소: 뿌리채소는 개 단위
    '뿌리채소': '개',
    // 과일: 모두 개 단위
    '국산과일': '개',
    '열대과일': '개',
    '베리류': 'g',
    // 유제품
    '우유/크림': 'ml',
    '버터/마가린': 'g',
    '달걀': '개',
    // 음료
    '물/탄산': 'ml',
    '주스/음료': 'ml',
    '유제품음료': 'ml',
    '주류': 'ml',
  };

  // ─── 공개 API ─────────────────────────────────────────────────────────────

  /// 카테고리에 대한 서브 카테고리 목록을 반환한다.
  static List<String> getSubCategories(StockCategory category) {
    return subCategoryMap[category] ?? [];
  }

  /// 서브 카테고리에 대한 부위/종류 목록을 반환한다.
  static List<String> getParts(String subCategory) {
    return partMap[subCategory] ?? [];
  }

  /// 카테고리와 서브 카테고리에 따른 기본 단위를 반환한다.
  ///
  /// 서브 카테고리 단위 > 카테고리 단위 순으로 우선순위 적용.
  static String getDefaultUnit(
    StockCategory category, {
    String? subCategory,
  }) {
    if (subCategory != null && subCategoryDefaultUnit.containsKey(subCategory)) {
      return subCategoryDefaultUnit[subCategory]!;
    }
    return categoryDefaultUnit[category] ?? '개';
  }

  /// 자동 입력될 재료명을 반환한다.
  ///
  /// subCategory + itemPart 조합으로 완성된 재료명을 생성한다.
  /// 예: subCategory="돼지고기", itemPart="목살" → "돼지고기 (목살)"
  static String buildAutoName({
    required String subCategory,
    String? itemPart,
  }) {
    if (itemPart != null && itemPart.isNotEmpty) {
      return '$subCategory ($itemPart)';
    }
    return subCategory;
  }

  /// 사용 가능한 단위 목록을 반환한다.
  static const List<String> allUnits = [
    'g',
    'kg',
    'ml',
    'L',
    '개',
    '봉지',
    '팩',
    '캔',
    '병',
    '상자',
    '줄기',
    '묶음',
    '인분',
    '컵',
    '큰술',
    '작은술',
  ];
}
