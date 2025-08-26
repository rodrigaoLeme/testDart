import '../../domain/entities/chat/chat.dart';
import '../models/chat/message_model.dart';
import '../models/dify/dify_message_model.dart';

class DifyMessageAdapter {
  static List<MessageModel> fromDify({
    required DifyMessageModel difyMessage,
  }) {
    final messages = <MessageModel>[];

    // Mensagem do usuário (pergunta)
    if (difyMessage.query.isNotEmpty) {
      messages.add(MessageModel(
        id: '${difyMessage.id}_user',
        conversationId: difyMessage.conversationId,
        content: difyMessage.query,
        type: MessageType.user,
        timestamp: difyMessage.createdAt,
        status: MessageStatus.sent,
        metadata: {
          'dify_message_id': difyMessage.id,
          'dify_conversation_id': difyMessage.conversationId,
          'parent_message_id': difyMessage.parentMessageId,
        },
      ));
    }

    // Mensagem do assistente (resposta)
    if (difyMessage.answer.isNotEmpty) {
      messages.add(MessageModel(
        id: '${difyMessage.id}_assistant',
        conversationId: difyMessage.conversationId,
        content: difyMessage.answer,
        type: MessageType.assistant,
        timestamp: difyMessage.createdAt
            .add(const Duration(seconds: 1)), // Ligeiramente depois
        status: MessageStatus.sent,
        metadata: {
          'dify_message_id': difyMessage.id,
          'dify_conversation_id': difyMessage.conversationId,
          'parent_message_id': difyMessage.parentMessageId,
          'retriever_resources':
              _encodeRetrieverResources(difyMessage.retrieverResources),
          'agent_thoughts': _encodeAgentThoughts(difyMessage.agentThoughts),
          'feedback': difyMessage.feedback?.toJson(),
        },
      ));
    }

    return messages;
  }

  // Converte lista de DifyMessageModel para lista de MessageModel
  static List<MessageModel> fromDifyList({
    required List<DifyMessageModel> difyMessages,
  }) {
    final messages = <MessageModel>[];

    for (final difyMessage in difyMessages) {
      messages.addAll(fromDify(difyMessage: difyMessage));
    }

    // Ordem cronológica
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return messages;
  }

  // Extrai contexto do Dify
  static Map<String, dynamic> extractDifyMetadata(
      DifyMessageModel difyMessage) {
    return {
      'dify_message_id': difyMessage.id,
      'dify_conversation_id': difyMessage.conversationId,
      'parent_message_id': difyMessage.parentMessageId,
      'status': difyMessage.status,
      'error': difyMessage.error,
      'has_retriever_resources': difyMessage.retrieverResources.isNotEmpty,
      'has_agent_thoughts': difyMessage.agentThoughts.isNotEmpty,
      'has_files': difyMessage.messageFiles.isNotEmpty,
    };
  }

  static bool isActiveMessage(DifyMessageModel difyMessage) {
    return difyMessage.status == 'normal' && difyMessage.error == null;
  }

  static List<Map<String, dynamic>> _encodeRetrieverResources(
    List<DifyRetrieverResource> resources,
  ) {
    return resources.map((resource) => resource.toJson()).toList();
  }

  static List<Map<String, dynamic>> _encodeAgentThoughts(
    List<DifyAgentThought> thoughts,
  ) {
    return thoughts.map((thought) => thought.toJson()).toList();
  }

  static List<DifyRetrieverResource> decodeRetrieverResources(
    Map<String, dynamic> metadata,
  ) {
    final resourcesJson = metadata['retriever_resources'] as List<dynamic>?;
    if (resourcesJson == null) return [];

    return resourcesJson
        .map((json) =>
            DifyRetrieverResource.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static List<DifyAgentThought> decodeAgentThoughts(
    Map<String, dynamic> metadata,
  ) {
    final thoughtsJson = metadata['agent_thoughts'] as List<dynamic>?;
    if (thoughtsJson == null) return [];

    return thoughtsJson
        .map((json) => DifyAgentThought.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Map<String, dynamic> toUserQuery(MessageModel message) {
    return {
      'query': message.content,
      'user': message.metadata['user_id'] ?? 'unknown',
      'conversation_id': message.metadata['dify_conversation_id'],
      'inputs': {},
    };
  }

  static String generateContentPreview(DifyMessageModel difyMessage) {
    if (difyMessage.answer.isNotEmpty) {
      final content = difyMessage.answer.trim();
      if (content.length > 100) {
        return '${content.substring(0, 97)}...';
      }
      return content;
    }

    if (difyMessage.query.isNotEmpty) {
      final content = difyMessage.query.trim();
      if (content.length > 100) {
        return '${content.substring(0, 97)}...';
      }
      return content;
    }

    return 'Mensagem vazia';
  }
}
