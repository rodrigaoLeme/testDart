class ReportEntity {
  final String userId;
  final String message;
  final String conversationId;
  final String userQuery;
  final String userFeedback;
  final String messageId;
  final DateTime timestamp;

  ReportEntity({
    required this.userId,
    required this.message,
    required this.conversationId,
    required this.userQuery,
    required this.userFeedback,
    required this.messageId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'message': message,
      'conversation_id': conversationId,
      'user_query': userQuery,
      'user_feedback': userFeedback,
      'message_id': messageId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
