import '../../entities/chat/chat.dart';

abstract class SendMessage {
  Future<MessageEntity> send({
    required String conversationId,
    required String content,
    required MessageType type,
    Map<String, dynamic>? metadata,
  });
}
