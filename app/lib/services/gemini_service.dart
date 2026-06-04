import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';

/// Gemini API 호출 서비스.
///
/// Dio를 사용하여 Gemini REST API를 직접 호출한다.
/// API 키는 [FlutterSecureStorage]에서 안전하게 읽는다.
///
/// 설정: `docs/core/product_map.md §7.1`
class GeminiService {
  GeminiService({
    required Dio dio,
    required FlutterSecureStorage storage,
  })  : _dio = dio, // ignore: prefer_initializing_formals
        _storage = storage; // ignore: prefer_initializing_formals

  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const String _storageKey = 'gemini_api_key';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  static const int _maxRetries = 2;
  static const double _temperature = 0.7;
  static const int _maxTokens = 2048;

  /// Gemini API 키를 FlutterSecureStorage에 저장한다.
  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _storageKey, value: apiKey);
  }

  /// Gemini API 키가 설정되어 있는지 확인한다.
  Future<bool> hasApiKey() async {
    final key = await _storage.read(key: _storageKey);
    return key != null && key.isNotEmpty;
  }

  /// 프롬프트를 Gemini API에 전송하고 JSON 텍스트 응답을 반환한다.
  ///
  /// - 에러 시 최대 2회 재시도 (지수 백오프: 2s, 4s)
  /// - API 키 미설정 시 [AppError.network] 반환
  Future<Result<String, AppError>> generateContent(String prompt) async {
    final stored = await _storage.read(key: _storageKey);
    final apiKey = stored?.trim() ?? '';
    if (apiKey.isEmpty) {
      return const Result.failure(
        AppError.network('Gemini API 키가 설정되지 않았습니다. 설정 화면에서 키를 입력해 주세요.'),
      );
    }

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          '$_baseUrl?key=$apiKey',
          data: {
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {
              'temperature': _temperature,
              'maxOutputTokens': _maxTokens,
              'responseMimeType': 'application/json',
              // thinking 토큰 비활성화: 레시피 JSON 생성에 불필요하며
              // 0 없이는 요청당 토큰이 급증해 RPM 한도를 빠르게 소진.
              'thinkingConfig': {
                'thinkingBudget': 0,
              },
            },
          },
          options: Options(
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Content-Type': 'application/json'},
          ),
        );

        final text = response.data?['candidates']?[0]?['content']?['parts']
            ?[0]?['text'];
        if (text == null) {
          return const Result.failure(
            AppError.parsing('Gemini 응답이 비어있습니다.'),
          );
        }
        return Result.success(text as String);
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        // ignore: avoid_print
        print('[GeminiService] HTTP $status | body: ${e.response?.data}');
        if (status == 401 || status == 403 || status == 400) {
          return Result.failure(_mapDioError(e));
        }
        // 429: retryDelay가 90초 이하면 자동 대기 후 재시도
        if (status == 429) {
          final delaySecs = _parseRetryDelay(e.response?.data);
          if (delaySecs != null && delaySecs <= 90 && attempt < _maxRetries) {
            // ignore: avoid_print
            print('[GeminiService] 429 → ${delaySecs}s 대기 후 재시도');
            await Future.delayed(Duration(seconds: delaySecs));
            continue;
          }
          return Result.failure(_mapDioError(e));
        }
        if (attempt >= _maxRetries) {
          return Result.failure(_mapDioError(e));
        }
        // 지수 백오프: 2s, 4s (5xx·timeout 등 일시적 오류)
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      } catch (e) {
        return Result.failure(AppError.unknown(e));
      }
    }

    return const Result.failure(AppError.unknown('알 수 없는 오류'));
  }

  /// Gemini 429 응답의 retryDelay 파싱.
  ///
  /// 응답 예시: {"error": {"details": [{"retryDelay": "60s"}]}}
  /// 파싱 실패 시 null 반환.
  int? _parseRetryDelay(dynamic body) {
    try {
      if (body is! Map) return null;
      final error = body['error'];
      if (error is! Map) return null;
      final details = error['details'];
      if (details is! List) return null;
      for (final detail in details) {
        if (detail is Map && detail['retryDelay'] is String) {
          final raw = detail['retryDelay'] as String; // e.g. "60s"
          final secs = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
          return secs;
        }
      }
    } catch (_) {}
    return null;
  }

  AppError _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    // Google API 에러 메시지 추출
    String? googleMessage;
    if (body is Map) {
      final error = body['error'];
      if (error is Map) {
        googleMessage = error['message']?.toString();
      }
    }

    switch (status) {
      case 401:
      case 403:
        return AppError.network(
          'API 키가 유효하지 않습니다. 설정에서 키를 확인해 주세요.'
          '${googleMessage != null ? '\n[$googleMessage]' : ''}',
        );
      case 429:
        return AppError.network(
          'API 요청 한도를 초과했습니다. 잠시 후 다시 시도해 주세요.'
          '${googleMessage != null ? '\n[$googleMessage]' : ''}',
        );
      case 400:
        return AppError.network(
          '잘못된 요청입니다.'
          '${googleMessage != null ? '\n[$googleMessage]' : '\n${body}'}',
        );
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return const AppError.network('요청 시간이 초과되었습니다. 네트워크를 확인해 주세요.');
        }
        return AppError.network('네트워크 오류 (HTTP $status): ${e.message}'
            '${googleMessage != null ? '\n[$googleMessage]' : ''}');
    }
  }
}
