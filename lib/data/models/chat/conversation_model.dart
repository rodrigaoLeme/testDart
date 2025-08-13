import 'dart:convert';

import '../../../domain/entities/chat/chat.dart';
import './message_model.dart';

class ConversationModel {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final bool isActive;
  final String lastMessage;
  final List<MessageModel> messages;

  ConversationModel({
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

  factory ConversationModel.fromEntity(ConversationEntity entity) {
    return ConversationModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      messageCount: entity.messageCount,
      isActive: entity.isActive,
      lastMessage: entity.lastMessage,
      messages:
          entity.messages.map((msg) => MessageModel.fromEntity(msg)).toList(),
    );
  }

  factory ConversationModel.fromFirestore(Map<String, dynamic> data) {
    return ConversationModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      title: data['title'] as String,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      updatedAt: (data['updatedAt'] as dynamic).toDate(),
      messageCount: data['messageCount'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      lastMessage: data['lastMessage'] as String? ?? '',
      messages: [], // Mensagens são carregadas separadamente
    );
  }

  factory ConversationModel.fromCache(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messageCount: json['messageCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      lastMessage: json['lastMessage'] as String? ?? '',
      messages: (json['messages'] as List<dynamic>?)
              ?.map((msgJson) => MessageModel.fromCache(msgJson))
              .toList() ??
          [],
    );
  }

  ConversationEntity toEntity() {
    return ConversationEntity(
      id: id,
      userId: userId,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messageCount: messageCount,
      isActive: isActive,
      lastMessage: lastMessage,
      messages: messages.map((msg) => msg.toEntity()).toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'messageCount': messageCount,
      'isActive': isActive,
      'lastMessage': lastMessage,
      // Mensagens não são salvas no documento principal
    };
  }

  Map<String, dynamic> toCache() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messageCount': messageCount,
      'isActive': isActive,
      'lastMessage': lastMessage,
      'messages': messages.map((msg) => msg.toCache()).toList(),
    };
  }

  String toCacheString() => jsonEncode(toCache());

  static List<ConversationModel> fromCacheString(String cacheString) {
    final List<dynamic> jsonList = jsonDecode(cacheString);
    return jsonList.map((json) => ConversationModel.fromCache(json)).toList();
  }

  static String listToCacheString(List<ConversationModel> conversations) {
    final jsonList = conversations.map((conv) => conv.toCache()).toList();
    return jsonEncode(jsonList);
  }

  // Helper para criar nova conversa
  static ConversationModel createNew({
    required String userId,
    required String firstMessage,
  }) {
    final now = DateTime.now();
    final conversationId = 'conv_${now.millisecondsSinceEpoch}';

    return ConversationModel(
      id: conversationId,
      userId: userId,
      title: ConversationEntity.generateTitleFromMessage(firstMessage),
      createdAt: now,
      updatedAt: now,
      messageCount: 0,
      isActive: true,
      lastMessage: firstMessage,
    );
  }
}
