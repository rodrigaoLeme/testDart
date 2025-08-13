import '../../../data/models/dify/dify.dart';

abstract class SendToDify {
  Stream<DifyStreamResponse> sendMessage({
    required String message,
    required String conversationId,
    String? userId,
  });
}
