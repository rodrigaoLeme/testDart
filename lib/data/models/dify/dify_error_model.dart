class DifyErrorModel {
  final String code;
  final String message;
  final String? status;

  DifyErrorModel({
    required this.code,
    required this.message,
    this.status,
  });

  factory DifyErrorModel.fromJson(Map<String, dynamic> json) {
    return DifyErrorModel(
      code: json['code'] as String,
      message: json['message'] as String,
      status: json['status'] as String?,
    );
  }
}
