import 'package:freezed_annotation/freezed_annotation.dart';

part 'cooking_chat_message.freezed.dart';

/// 요리 도우미 채팅 메시지의 발화자.
enum ChatRole { user, assistant }

/// 요리 도우미 채팅 메시지.
@freezed
abstract class CookingChatMessage with _$CookingChatMessage {
  const factory CookingChatMessage({
    required ChatRole role,
    required String content,
    required DateTime timestamp,
  }) = _CookingChatMessage;
}
