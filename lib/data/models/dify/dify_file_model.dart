class DifyFileModel {
  final String type;
  final String transferMethod;
  final String url;

  DifyFileModel({
    required this.type,
    required this.transferMethod,
    required this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'transfer_method': transferMethod,
      'url': url,
    };
  }
}
