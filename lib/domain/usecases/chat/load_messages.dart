import '../../entities/chat/chat.dart';

abstract class LoadMessages {
  Future<List<MessageEntity>> load({
    required String conversationId,
    int limit = 30,
    String? startAfter,
  });
}
