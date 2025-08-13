import 'dify.dart';

class DifyResponseModel {
  final String event;
  final String? taskId;
  final String? id;
  final String? answer;
  final String? conversationId;
  final int? createdAt;
  final Map<String, dynamic>? metadata;
  final DifyUsageModel? usage;

  DifyResponseModel({
    required this.event,
    this.taskId,
    this.id,
    this.answer,
    this.conversationId,
    this.createdAt,
    this.metadata,
    this.usage,
  });

  factory DifyResponseModel.fromJson(Map<String, dynamic> json) {
    return DifyResponseModel(
      event: json['event'] as String,
      taskId: json['task_id'] as String?,
      id: json['id'] as String?,
      answer: json['answer'] as String?,
      conversationId: json['conversation_id'] as String?,
      createdAt: json['created_at'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      usage: json['usage'] != null
          ? DifyUsageModel.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isComplete => event == 'message_end';
  bool get isStreaming => event == 'message' || event == 'message_replace';
  bool get isError => event == 'error';
}
