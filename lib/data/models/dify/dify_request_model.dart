import 'dify.dart';

class DifyRequestModel {
  final String query;
  final String user;
  final String conversationId;
  final Map<String, dynamic> inputs;
  final bool responseMode;
  final List<DifyFileModel> files;

  DifyRequestModel({
    required this.query,
    required this.user,
    this.conversationId = '',
    this.inputs = const {},
    this.responseMode = true, // true = streaming, false = blocking
    this.files = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'user': user,
      'conversation_id': conversationId,
      'inputs': inputs,
      'response_mode': responseMode ? 'streaming' : 'blocking',
      'files': files.map((file) => file.toJson()).toList(),
    };
  }
}
