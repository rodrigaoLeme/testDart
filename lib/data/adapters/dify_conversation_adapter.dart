import '../models/chat/conversation_model.dart';
import '../models/dify/dify_conversation_model.dart';

// Adapter para converter entre Dify models e App models
class DifyConversationAdapter {
  // Converte DifyConversationModel para ConversationModel
  static ConversationModel fromDify({
    required DifyConversationModel difyConversation,
    required String userId,
  }) {
    return ConversationModel(
      id: difyConversation.id,
      userId: userId,
      title: difyConversation.name,
      createdAt: difyConversation.createdAt,
      updatedAt: difyConversation.updatedAt,
      messageCount: 0,
      isActive: difyConversation.status == 'normal',
      lastMessage: _extractLastMessageFromName(difyConversation.name),
      messages: [],
    );
  }

  // Converte lista de DifyConversationModel para lista de ConversationModel
  static List<ConversationModel> fromDifyList({
    required List<DifyConversationModel> difyConversations,
    required String userId,
  }) {
    return difyConversations
        .map((difyConv) => fromDify(
              difyConversation: difyConv,
              userId: userId,
            ))
        .toList();
  }

  static String _extractLastMessageFromName(String name) {
    final cleaned = name.trim();
    if (cleaned.length > 100) {
      return '${cleaned.substring(0, 97)}...';
    }
    return cleaned;
  }

  static bool isActive(DifyConversationModel difyConversation) {
    return difyConversation.status == 'normal';
  }

  static Map<String, dynamic> toDifyJson(ConversationModel conversation) {
    return {
      'id': conversation.id,
      'name': conversation.title,
      'inputs': {},
      'status': conversation.isActive ? 'normal' : 'inactive',
      'introduction': null,
      'created_at': conversation.createdAt.millisecondsSinceEpoch ~/ 1000,
      'updated_at': conversation.updatedAt.millisecondsSinceEpoch ~/ 1000,
    };
  }
}
