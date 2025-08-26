import '../../../../domain/usecases/chat/load_conversations.dart';
import '../../repositories/dify_chat_repository_factory.dart';

LoadConversations makeLoadConversations() => makeDifyChatRepository();
