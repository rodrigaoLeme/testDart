class DifyUsageModel {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final double? promptPrice;
  final double? completionPrice;
  final double? totalPrice;
  final String? currency;

  DifyUsageModel({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    this.promptPrice,
    this.completionPrice,
    this.totalPrice,
    this.currency,
  });

  factory DifyUsageModel.fromJson(Map<String, dynamic> json) {
    return DifyUsageModel(
      promptTokens: json['prompt_tokens'] as int,
      completionTokens: json['completion_tokens'] as int,
      totalTokens: json['total_tokens'] as int,
      promptPrice: json['prompt_price'] as double?,
      completionPrice: json['completion_price'] as double?,
      totalPrice: json['total_price'] as double?,
      currency: json['currency'] as String?,
    );
  }
}
