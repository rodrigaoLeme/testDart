class FAQItemEntity {
  final String id;
  final int order;
  final bool active;
  final DateTime createdAt;
  final String title;
  final String description;

  FAQItemEntity({
    required this.id,
    required this.order,
    required this.active,
    required this.createdAt,
    required this.title,
    required this.description,
  });
}
