import '../../../domain/entities/chat/chat.dart';
import '../../../ui/helpers/helpers.dart';
import '../../../ui/mixins/navigation_data.dart';
import '../../mixins/mixins.dart';

abstract class ChatPresenter {
  // Streams para reatividade
  Stream<List<MessageEntity>> get messagesStream;
  Stream<ConversationEntity?> get currentConversationStream;
  Stream<NavigationData?> get navigateToStream;
  Stream<UIError?> get mainErrorStream;
  Stream<LoadingData> get isLoadingStream;
  Stream<String> get typingTextStream;
  Stream<bool> get isThinkingStream;

  // Getters síncronos
  List<MessageEntity> get messages;
  ConversationEntity? get currentConversation;
  bool get isTyping;
  bool get isThinking;

  // Ações
  Future<void> loadConversation(String conversationId);
  Future<void> createNewConversation(String firstMessage);
  Future<void> sendMessage(String content);
  Future<void> loadMoreMessages();
  void goBack();
  void clearCurrentConversation();
}
