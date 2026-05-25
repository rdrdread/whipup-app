import 'package:speech_to_text/speech_to_text.dart';
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';

/// 음성 입력 서비스.
///
/// speech_to_text 패키지를 사용하여 음성을 텍스트로 변환한다.
/// Phase 1.3: 재료 음성 입력에 사용.
class VoiceInputService {
  VoiceInputService() : _speechToText = SpeechToText();

  final SpeechToText _speechToText;

  bool _isInitialized = false;

  /// 음성 인식 서비스를 초기화한다.
  Future<Result<void, AppError>> initialize() async {
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          // 에러 로깅 (Sentry 연동 시 확장)
        },
      );
      if (!_isInitialized) {
        return const Result.failure(
          AppError.unknown('음성 인식을 초기화할 수 없습니다. 마이크 권한을 확인해 주세요.'),
        );
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppError.unknown(e));
    }
  }

  /// 음성 인식 가능 여부.
  bool get isAvailable => _isInitialized && _speechToText.isAvailable;

  /// 현재 청취 중인지 여부.
  bool get isListening => _speechToText.isListening;

  /// 음성 청취를 시작하고 인식된 텍스트 스트림을 반환한다.
  Future<Result<void, AppError>> startListening({
    required void Function(String text) onResult,
    String locale = 'ko_KR',
  }) async {
    if (!_isInitialized) {
      final initResult = await initialize();
      if (initResult.isFailure) return initResult;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: locale,
          listenMode: ListenMode.dictation,
          partialResults: true,
        ),
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppError.unknown('음성 인식 시작 실패: $e'));
    }
  }

  /// 음성 청취를 중지한다.
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  /// 음성 청취를 취소한다.
  Future<void> cancelListening() async {
    await _speechToText.cancel();
  }
}
