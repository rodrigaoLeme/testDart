class DifyStreamResponse {
  final String content;
  final bool isComplete;
  final DifyMetadata? metadata;

  DifyStreamResponse({
    required this.content,
    required this.isComplete,
    this.metadata,
  });
}

class DifyMetadata {
  final String? conversationId;
  final String? messageId;

  DifyMetadata({
    this.conversationId,
    this.messageId,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (conversationId != null) {
      map['dify_conversation_id'] = conversationId!;
    }
    if (messageId != null) {
      map['dify_message_id'] = messageId!;
    }
    return map;
  }
}
