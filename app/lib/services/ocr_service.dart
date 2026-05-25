import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:whipup/core/errors/app_error.dart';
import 'package:whipup/core/result.dart';

/// OCR(광학 문자 인식) 서비스.
///
/// Google ML Kit Text Recognition을 사용하여
/// 이미지에서 텍스트를 추출한다.
///
/// Phase 1.2: 영수증 텍스트 추출에 사용.
class OcrService {
  OcrService() : _textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);

  final TextRecognizer _textRecognizer;

  /// 이미지 파일 경로에서 텍스트를 인식한다.
  Future<Result<String, AppError>> recognizeText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await _textRecognizer.processImage(inputImage);
      return Result.success(recognized.text);
    } catch (e) {
      return Result.failure(AppError.unknown('텍스트 인식 실패: $e'));
    }
  }

  /// 리소스를 해제한다.
  void dispose() {
    _textRecognizer.close();
  }
}
