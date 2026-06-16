import 'package:speech_to_text/speech_to_text.dart';
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';

/// 음성 입력 서비스.
///
/// speech_to_text 패키지를 사용하여 음성을 텍스트로 변환한다.
/// Phase 1.3: 재료 음성 입력에 사용.
///
/// pauseFor(4초) 초과로 플러그인이 자동 종료될 때 300ms 후 자동 재시작하여
/// 긴 발화도 끊김 없이 인식한다. _lastCommittedWords는 유지되므로
/// Android STT가 이전 세션 텍스트를 첫 partial로 반환해도 dedup으로 차단된다.
class VoiceInputService {
  VoiceInputService() : _speechToText = SpeechToText();

  final SpeechToText _speechToText;
  bool _isInitialized = false;

  // 청취 유지 여부 — stopListening() 시 false 로 설정하여 자동 재시작 방지
  bool _shouldListen = false;

  // 자동 재시작을 위해 저장된 청취 파라미터
  void Function(String text, {required bool isFinal})? _onResult;
  void Function(double level)? _onSoundLevel;
  String _locale = 'ko_KR';

  /// 음성 인식 서비스를 초기화한다.
  Future<Result<void, AppError>> initialize() async {
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {},
        onStatus: _handleStatus,
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

  /// 음성 청취를 시작한다.
  ///
  /// [onResult] 인식된 텍스트(현재 utterance), [isFinal] 최종 결과 여부.
  Future<Result<void, AppError>> startListening({
    required void Function(String text, {required bool isFinal}) onResult,
    void Function(double level)? onSoundLevel,
    String locale = 'ko_KR',
  }) async {
    if (!_isInitialized) {
      final initResult = await initialize();
      if (initResult.isFailure) return initResult;
    }

    _shouldListen = true;
    _onResult = onResult;
    _onSoundLevel = onSoundLevel;
    _locale = locale;

    return _doListen();
  }

  /// 음성 청취를 중지한다.
  Future<void> stopListening() async {
    _shouldListen = false;
    await _speechToText.stop();
  }

  /// 음성 청취를 취소한다.
  Future<void> cancelListening() async {
    _shouldListen = false;
    await _speechToText.cancel();
  }

  // ─── 내부 ────────────────────────────────────────────────────────────────

  /// speech_to_text 상태 변화 핸들러.
  ///
  /// pauseFor 초과로 'done' 상태가 되면 300ms 후 자동 재시작한다.
  /// _lastCommittedWords는 화면 레이어에서 유지되므로 Android STT가 이전
  /// 세션의 텍스트를 첫 partial로 반환해도 dedup이 자동으로 차단한다.
  void _handleStatus(String status) {
    if (!_shouldListen) return;
    if (status == SpeechToText.doneStatus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_shouldListen && !_speechToText.isListening) {
          _doListen();
        }
      });
    }
  }

  Future<Result<void, AppError>> _doListen() async {
    if (!_shouldListen || !_isInitialized) return const Result.success(null);
    if (_speechToText.isListening) return const Result.success(null);
    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.recognizedWords.isEmpty) return;
          _onResult?.call(result.recognizedWords, isFinal: result.finalResult);
        },
        onSoundLevelChange: _onSoundLevel,
        listenOptions: SpeechListenOptions(
          localeId: _locale,
          listenMode: ListenMode.dictation,
          partialResults: true,
          pauseFor: const Duration(seconds: 4),
          listenFor: const Duration(minutes: 2),
        ),
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppError.unknown('음성 인식 시작 실패: $e'));
    }
  }
}
