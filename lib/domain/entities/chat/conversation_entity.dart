import 'chat.dart';

class ConversationEntity {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final bool isActive;
  final String lastMessage;
  final List<MessageEntity> messages;

  ConversationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    this.isActive = true,
    this.lastMessage = '',
    this.messages = const [],
  });

  ConversationEntity copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
    bool? isActive,
    String? lastMessage,
    List<MessageEntity>? messages,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      isActive: isActive ?? this.isActive,
      lastMessage: lastMessage ?? this.lastMessage,
      messages: messages ?? this.messages,
    );
  }

  // Helper para gerar título automático da primeira mensagem
  static String generateTitleFromMessage(String firstMessage) {
    if (firstMessage.trim().isEmpty) {
      return 'Nova Conversa';
    }

    final cleanMessage = firstMessage.trim();

    if (cleanMessage.length <= 50) {
      return cleanMessage;
    }

    final maxLength = cleanMessage.length < 47 ? cleanMessage.length : 47;
    return '${cleanMessage.substring(0, maxLength)}...';
  }
}
