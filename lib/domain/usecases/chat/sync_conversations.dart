import '../../entities/chat/chat.dart';

abstract class SyncConversations {
  Future<List<ConversationEntity>> sync({bool forceRefresh = false});
}
