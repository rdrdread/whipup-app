import 'package:dio/dio.dart';

/// 한국 음식 이미지 URL을 한국어 위키백과 API에서 가져오는 서비스.
///
/// 위키백과 이미지는 CC-BY-SA 라이선스로 무료 사용 가능.
/// 네트워크 실패 시 null 반환 → 호출 측에서 이모지 폴백.
class FoodImageService {
  FoodImageService() : _dio = _buildDio();

  final Dio _dio;

  static const _wikiSummary =
      'https://ko.wikipedia.org/api/rest_v1/page/summary';

  /// 요리명 → 위키백과 페이지 별칭 매핑.
  /// 요리명과 위키백과 표제어가 다른 경우에 사용.
  static const _aliases = <String, List<String>>{
    '계란볶음밥': ['계란볶음밥', '볶음밥'],
    '김치볶음밥': ['김치볶음밥', '볶음밥'],
    '참치김치볶음밥': ['참치볶음밥', '볶음밥'],
    '계란말이': ['달걀말이'],
    '계란국': ['달걀국'],
    '콩나물국': ['콩나물국밥'],
    '닭볶음탕': ['닭도리탕', '닭볶음탕'],
    '삼겹살구이': ['삼겹살'],
    '겉절이': ['겉절이'],
    '감자전': ['감자전'],
    '호박전': ['애호박전', '호박전'],
    '파전': ['파전'],
    '라볶이': ['라볶이'],
    '어묵볶음': ['어묵볶음'],
    '오므라이스': ['오므라이스'],
    '두부조림': ['두부조림'],
    '시금치나물': ['시금치나물'],
    '오이무침': ['오이무침'],
    '감자조림': ['감자조림'],
    '갈비찜': ['갈비찜'],
    '잡채': ['잡채'],
    '불고기': ['불고기'],
    '비빔밥': ['비빔밥'],
    '카레라이스': ['카레', '카레라이스'],
    '부대찌개': ['부대찌개'],
    '순두부찌개': ['순두부찌개'],
    '된장찌개': ['된장찌개'],
    '김치찌개': ['김치찌개'],
    '떡볶이': ['떡볶이'],
    '제육볶음': ['제육볶음'],
    '닭갈비': ['닭갈비'],
    '미역국': ['미역국'],
  };

  /// 요리명으로 이미지 URL을 조회한다.
  /// 성공 시 원본 이미지 URL, 없으면 썸네일 URL, 실패 시 null.
  Future<String?> fetchImageUrl(String dishName) async {
    final candidates = _aliases[dishName] ?? [dishName];

    for (final query in candidates) {
      final url = await _fetchFromWiki(query);
      if (url != null) return url;
    }
    return null;
  }

  Future<String?> _fetchFromWiki(String query) async {
    try {
      final response = await _dio.get(
        '$_wikiSummary/$query',
        options: Options(receiveTimeout: const Duration(seconds: 6)),
      );
      if (response.statusCode != 200) return null;
      final data = response.data as Map<String, dynamic>;
      return (data['originalimage']?['source'] as String?) ??
          (data['thumbnail']?['source'] as String?);
    } catch (_) {
      return null;
    }
  }

  static Dio _buildDio() {
    return Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 8),
    ));
  }
}
