class SuggestionEntity {
  final String id;
  final int order;
  final bool active;
  final DateTime createdAt;
  final String text;

  SuggestionEntity({
    required this.id,
    required this.order,
    required this.active,
    required this.createdAt,
    required this.text,
  });
}
