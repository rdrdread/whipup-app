import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:whipup/providers/recipe_providers.dart';
import 'package:whipup/services/voice_gemini_parser.dart';

part 'voice_provider.g.dart';

/// [VoiceGeminiParser] Provider.
///
/// GeminiService + PromptBuilder를 주입하여 음성 텍스트 파서를 제공한다.
@riverpod
VoiceGeminiParser voiceGeminiParser(Ref ref) {
  return VoiceGeminiParser(
    geminiService: ref.watch(geminiServiceProvider),
    promptBuilder: ref.watch(promptBuilderProvider),
  );
}
