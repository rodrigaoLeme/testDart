import '../../../domain/entities/entities.dart';

abstract class HomePresenter {
  Stream<UserEntity?> get currentUserStream;
  Stream<List<SuggestionEntity>> get suggestionsStream;
  Stream<List<ConversationEntity>> get conversationsStream;

  // Getters
  List<SuggestionEntity> get suggestions;
  List<ConversationEntity> get conversations;

  // User methods
  Future<void> loadCurrentUser();

  // Suggestions methods
  Future<void> loadSuggestions();
  List<SuggestionEntity> getRandomSuggestions();

  // Conversations methods
  Future<void> loadConversations();
  Future<void> refreshConversations();
  void addNewConversation(ConversationEntity conversation);
  void updateConversation(ConversationEntity conversation);
  void deleteConversation(String conversationId);
}
