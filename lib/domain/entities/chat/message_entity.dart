enum MessageType { user, assistant }

enum MessageStatus { sending, sent, failed }

class MessageEntity {
  final String id;
  final String conversationId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isTyping;
  final Map<String, dynamic> metadata;

  MessageEntity({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isTyping = false,
    this.metadata = const {},
  });

  MessageEntity copyWith({
    String? id,
    String? conversationId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    bool? isTyping,
    Map<String, dynamic>? metadata,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isTyping: isTyping ?? this.isTyping,
      metadata: metadata ?? this.metadata,
    );
  }
}
