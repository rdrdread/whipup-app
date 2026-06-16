import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:whipup/models/cooking_chat_message.dart';
import 'package:whipup/models/recipe.dart';
import 'package:whipup/providers/recipe_providers.dart';

part 'cooking_chat_provider.g.dart';

/// 요리 도우미 채팅 상태.
class CookingChatState {
  const CookingChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  final List<CookingChatMessage> messages;
  final bool isLoading;
  final String? error;

  CookingChatState copyWith({
    List<CookingChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      CookingChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

/// 레시피별 요리 도우미 채팅 Notifier.
///
/// [recipeId]를 키로 하는 family provider로 레시피마다 독립된 대화를 유지한다.
@riverpod
class CookingChat extends _$CookingChat {
  @override
  CookingChatState build(String recipeId) => const CookingChatState();

  /// 사용자 질문을 AI에 전송하고 응답을 상태에 반영한다.
  Future<void> ask({
    required Recipe recipe,
    required String question,
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    final userMsg = CookingChatMessage(
      role: ChatRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      clearError: true,
    );

    final prompt = _buildPrompt(recipe, trimmed);
    final gemini = ref.read(geminiServiceProvider);
    final result = await gemini.generateText(prompt);

    result.when(
      success: (text) {
        final assistantMsg = CookingChatMessage(
          role: ChatRole.assistant,
          content: text.trim(),
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, assistantMsg],
          isLoading: false,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.message,
        );
      },
    );
  }

  /// 대화 내역을 초기화한다.
  void clear() => state = const CookingChatState();

  String _buildPrompt(Recipe recipe, String question) {
    final ingredientList = recipe.ingredients
        .map((i) => '- ${i.name} ${i.amount}${i.unit}')
        .join('\n');

    final stepList = recipe.steps
        .map((s) => '${s.stepNumber}. [${s.phase.name}] ${s.description}')
        .join('\n');

    final prevMessages = state.messages;
    final historyBlock = prevMessages.isEmpty
        ? ''
        : '\n\n## 이전 대화:\n${prevMessages.map((m) {
            final role = m.role == ChatRole.user ? '사용자' : 'AI';
            return '$role: ${m.content}';
          }).join('\n')}';

    return '''
당신은 요리 중인 사용자를 돕는 친절한 요리 도우미입니다.
아래 레시피를 요리하는 도중 궁금한 점에 대해 간결하고 실용적으로 답변하세요.
3~4문장 이내로, 요리 현장에서 바로 적용할 수 있는 내용으로 답변하세요.

## 현재 요리 중인 레시피: ${recipe.title}
조리 시간: ${recipe.cookingTimeMinutes}분

## 재료:
$ingredientList

## 조리 순서:
$stepList${recipe.scienceNote != null ? '\n\n## 요리 과학:\n${recipe.scienceNote}' : ''}$historyBlock

## 사용자 질문:
$question

자연스러운 한국어로, 마크다운 없이 순수 텍스트로만 답변하세요.
''';
  }
}
