import '../../entities/chat/chat.dart';

abstract class CreateConversation {
  Future<ConversationEntity> create({
    required String userId,
    required String firstMessage,
  });
}
