import 'dart:convert';

import '../../../domain/entities/chat/chat.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isTyping;
  final Map<String, dynamic> metadata;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isTyping = false,
    this.metadata = const {},
  });

  // Constructor específico para mensagens com Dify context
  MessageModel.withDifyContext({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isTyping = false,
    Map<String, dynamic>? baseMetadata,
    String? difyConversationId,
    String? difyMessageId,
  }) : metadata = {
          ...?baseMetadata,
          if (difyConversationId != null)
            'dify_conversation_id': difyConversationId,
          if (difyMessageId != null) 'dify_message_id': difyMessageId,
        };

  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      conversationId: entity.conversationId,
      content: entity.content,
      type: entity.type,
      timestamp: entity.timestamp,
      status: entity.status,
      isTyping: entity.isTyping,
      metadata: entity.metadata,
    );
  }

  factory MessageModel.fromFirestore(Map<String, dynamic> data) {
    return MessageModel(
      id: data['id'] as String,
      conversationId: data['conversationId'] as String,
      content: data['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.user,
      ),
      timestamp: (data['timestamp'] as dynamic).toDate(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      isTyping: data['isTyping'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  factory MessageModel.fromCache(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.user,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      isTyping: json['isTyping'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      conversationId: conversationId,
      content: content,
      type: type,
      timestamp: timestamp,
      status: status,
      isTyping: isTyping,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'conversationId': conversationId,
      'content': content,
      'type': type.name,
      'timestamp': timestamp,
      'status': status.name,
      'isTyping': isTyping,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toCache() {
    return {
      'id': id,
      'conversationId': conversationId,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'isTyping': isTyping,
      'metadata': metadata,
    };
  }

  String toCacheString() => jsonEncode(toCache());

  static List<MessageModel> fromCacheString(String cacheString) {
    final List<dynamic> jsonList = jsonDecode(cacheString);
    return jsonList.map((json) => MessageModel.fromCache(json)).toList();
  }

  static String listToCacheString(List<MessageModel> messages) {
    final jsonList = messages.map((msg) => msg.toCache()).toList();
    return jsonEncode(jsonList);
  }

  // Helpers para acessar dados do Dify
  String? get difyConversationId => metadata['dify_conversation_id'] as String?;
  String? get difyMessageId => metadata['dify_message_id'] as String?;

  bool get hasDifyContext => difyConversationId != null;

  // Copy with para adicionar contexto Dify posteriormente
  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    bool? isTyping,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
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

  // Adiciona contexto Dify a uma mensagem existente
  MessageModel withDifyContext({
    String? difyConversationId,
    String? difyMessageId,
  }) {
    final newMetadata = Map<String, dynamic>.from(metadata);

    if (difyConversationId != null) {
      newMetadata['dify_conversation_id'] = difyConversationId;
    }

    if (difyMessageId != null) {
      newMetadata['dify_message_id'] = difyMessageId;
    }

    return copyWith(metadata: newMetadata);
  }
}
