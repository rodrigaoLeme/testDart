import '../../../data/adapters/dify_load_messages_adapter.dart';
import '../../../domain/usecases/chat/load_messages.dart';
import '../repositories/dify_chat_repository_factory.dart';

LoadMessages makeDifyLoadMessagesAdapter() => DifyLoadMessagesAdapter(
      difyChatRepository: makeDifyChatRepository(),
    );
