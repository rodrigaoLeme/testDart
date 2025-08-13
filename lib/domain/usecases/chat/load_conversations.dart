import '../../entities/chat/chat.dart';

abstract class LoadConversations {
  Future<List<ConversationEntity>> load({
    int limit = 20,
    String? startAfter,
  });
}
