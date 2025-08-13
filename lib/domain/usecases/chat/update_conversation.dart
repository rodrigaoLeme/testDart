import '../../entities/chat/chat.dart';

abstract class UpdateConversation {
  Future<ConversationEntity> update(ConversationEntity conversation);
}
