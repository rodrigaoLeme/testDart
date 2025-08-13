import '../../../../domain/usecases/chat/load_conversations.dart';
import '../../repositories/chat_repository_factory.dart';

LoadConversations makeLoadConversations() => makeChatRepository();
