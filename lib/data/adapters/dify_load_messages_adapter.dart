import '../../domain/entities/chat/chat.dart';
import '../../domain/usecases/chat/load_messages.dart';
import '../repositories/dify_chat_repository.dart';

class DifyLoadMessagesAdapter implements LoadMessages {
  final DifyChatRepository difyChatRepository;

  DifyLoadMessagesAdapter({
    required this.difyChatRepository,
  });

  @override
  Future<List<MessageEntity>> load({
    required String conversationId,
    int limit = 30,
    String? startAfter,
  }) async {
    return await difyChatRepository.getMessages(
      conversationId: conversationId,
      limit: limit,
      startAfter: startAfter,
    );
  }
}
