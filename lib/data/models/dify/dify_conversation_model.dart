class DifyConversationModel {
  final String id;
  final String name;
  final Map<String, dynamic> inputs;
  final String status;
  final String? introduction;
  final DateTime createdAt;
  final DateTime updatedAt;

  DifyConversationModel({
    required this.id,
    required this.name,
    required this.inputs,
    required this.status,
    this.introduction,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DifyConversationModel.fromJson(Map<String, dynamic> json) {
    return DifyConversationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      inputs: Map<String, dynamic>.from(json['inputs'] ?? {}),
      status: json['status'] as String,
      introduction: json['introduction'] as String?,
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'inputs': inputs,
      'status': status,
      'introduction': introduction,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    throw ArgumentError('Invalid timestamp format: $timestamp');
  }

  @override
  String toString() {
    return 'DifyConversationModel(id: $id, name: $name, status: $status)';
  }
}

class DifyConversationsResponse {
  final List<DifyConversationModel> data;
  final bool hasMore;
  final int limit;

  DifyConversationsResponse({
    required this.data,
    required this.hasMore,
    required this.limit,
  });

  factory DifyConversationsResponse.fromJson(Map<String, dynamic> json) {
    return DifyConversationsResponse(
      data: (json['data'] as List<dynamic>)
          .map((item) =>
              DifyConversationModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool,
      limit: json['limit'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((conv) => conv.toJson()).toList(),
      'has_more': hasMore,
      'limit': limit,
    };
  }

  @override
  String toString() {
    return 'DifyConversationsResponse(data: ${data.length} items, hasMore: $hasMore)';
  }
}
