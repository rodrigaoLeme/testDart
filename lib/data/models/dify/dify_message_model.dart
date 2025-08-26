// Model de uma mensagem retornada pela API do Dify
class DifyMessageModel {
  final String id;
  final String conversationId;
  final String? parentMessageId;
  final Map<String, dynamic> inputs;
  final String query;
  final String answer;
  final List<DifyMessageFile> messageFiles;
  final DifyFeedback? feedback;
  final List<DifyRetrieverResource> retrieverResources;
  final DateTime createdAt;
  final List<DifyAgentThought> agentThoughts;
  final String status;
  final String? error;

  DifyMessageModel({
    required this.id,
    required this.conversationId,
    this.parentMessageId,
    required this.inputs,
    required this.query,
    required this.answer,
    required this.messageFiles,
    this.feedback,
    required this.retrieverResources,
    required this.createdAt,
    required this.agentThoughts,
    required this.status,
    this.error,
  });

  factory DifyMessageModel.fromJson(Map<String, dynamic> json) {
    return DifyMessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      parentMessageId: json['parent_message_id'] as String?,
      inputs: Map<String, dynamic>.from(json['inputs'] ?? {}),
      query: json['query'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      messageFiles: (json['message_files'] as List<dynamic>?)
              ?.map((file) =>
                  DifyMessageFile.fromJson(file as Map<String, dynamic>))
              .toList() ??
          [],
      feedback: json['feedback'] != null
          ? DifyFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
      retrieverResources: (json['retriever_resources'] as List<dynamic>?)
              ?.map((resource) => DifyRetrieverResource.fromJson(
                  resource as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['created_at'] as int) * 1000),
      agentThoughts: (json['agent_thoughts'] as List<dynamic>?)
              ?.map((thought) =>
                  DifyAgentThought.fromJson(thought as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] as String? ?? 'normal',
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'parent_message_id': parentMessageId,
      'inputs': inputs,
      'query': query,
      'answer': answer,
      'message_files': messageFiles.map((file) => file.toJson()).toList(),
      'feedback': feedback?.toJson(),
      'retriever_resources':
          retrieverResources.map((resource) => resource.toJson()).toList(),
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'agent_thoughts':
          agentThoughts.map((thought) => thought.toJson()).toList(),
      'status': status,
      'error': error,
    };
  }

  @override
  String toString() {
    return 'DifyMessageModel(id: $id, query: $query, answer: ${answer.length} chars)';
  }
}

// Arquivo anexado a mensagem
class DifyMessageFile {
  final String id;
  final String type;
  final String url;
  final String belongsTo;

  DifyMessageFile({
    required this.id,
    required this.type,
    required this.url,
    required this.belongsTo,
  });

  factory DifyMessageFile.fromJson(Map<String, dynamic> json) {
    return DifyMessageFile(
      id: json['id'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      belongsTo: json['belongs_to'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'belongs_to': belongsTo,
    };
  }
}

// Feedback para a messagem
class DifyFeedback {
  final String rating; // 'like' ou 'dislike'

  DifyFeedback({required this.rating});

  factory DifyFeedback.fromJson(Map<String, dynamic> json) {
    return DifyFeedback(rating: json['rating'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'rating': rating};
  }
}

class DifyRetrieverResource {
  final int position;
  final String datasetId;
  final String datasetName;
  final String documentId;
  final String documentName;
  final String dataSourceType;
  final String segmentId;
  final String retrieverFrom;
  final double score;
  final String content;

  DifyRetrieverResource({
    required this.position,
    required this.datasetId,
    required this.datasetName,
    required this.documentId,
    required this.documentName,
    required this.dataSourceType,
    required this.segmentId,
    required this.retrieverFrom,
    required this.score,
    required this.content,
  });

  factory DifyRetrieverResource.fromJson(Map<String, dynamic> json) {
    return DifyRetrieverResource(
      position: json['position'] as int,
      datasetId: json['dataset_id'] as String,
      datasetName: json['dataset_name'] as String,
      documentId: json['document_id'] as String,
      documentName: json['document_name'] as String,
      dataSourceType: json['data_source_type'] as String,
      segmentId: json['segment_id'] as String,
      retrieverFrom: json['retriever_from'] as String,
      score: (json['score'] as num).toDouble(),
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'dataset_id': datasetId,
      'dataset_name': datasetName,
      'document_id': documentId,
      'document_name': documentName,
      'data_source_type': dataSourceType,
      'segment_id': segmentId,
      'retriever_from': retrieverFrom,
      'score': score,
      'content': content,
    };
  }
}

class DifyAgentThought {
  final String id;
  final String? chainId;
  final String messageId;
  final int position;
  final String thought;
  final String tool;
  final Map<String, dynamic> toolLabels;
  final String toolInput;
  final DateTime createdAt;
  final String observation;
  final List<String> files;

  DifyAgentThought({
    required this.id,
    this.chainId,
    required this.messageId,
    required this.position,
    required this.thought,
    required this.tool,
    required this.toolLabels,
    required this.toolInput,
    required this.createdAt,
    required this.observation,
    required this.files,
  });

  factory DifyAgentThought.fromJson(Map<String, dynamic> json) {
    return DifyAgentThought(
      id: json['id'] as String,
      chainId: json['chain_id'] as String?,
      messageId: json['message_id'] as String,
      position: json['position'] as int,
      thought: json['thought'] as String? ?? '',
      tool: json['tool'] as String? ?? '',
      toolLabels: Map<String, dynamic>.from(json['tool_labels'] ?? {}),
      toolInput: json['tool_input'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['created_at'] as int) * 1000),
      observation: json['observation'] as String? ?? '',
      files: (json['files'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chain_id': chainId,
      'message_id': messageId,
      'position': position,
      'thought': thought,
      'tool': tool,
      'tool_labels': toolLabels,
      'tool_input': toolInput,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'observation': observation,
      'files': files,
    };
  }
}

// Response model para o endpoint GET /messages
class DifyMessagesResponse {
  final List<DifyMessageModel> data;
  final bool hasMore;
  final int limit;

  DifyMessagesResponse({
    required this.data,
    required this.hasMore,
    required this.limit,
  });

  factory DifyMessagesResponse.fromJson(Map<String, dynamic> json) {
    return DifyMessagesResponse(
      data: (json['data'] as List<dynamic>)
          .map(
              (item) => DifyMessageModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool,
      limit: json['limit'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((msg) => msg.toJson()).toList(),
      'has_more': hasMore,
      'limit': limit,
    };
  }

  @override
  String toString() {
    return 'DifyMessagesResponse(data: ${data.length} messages, hasMore: $hasMore)';
  }
}
