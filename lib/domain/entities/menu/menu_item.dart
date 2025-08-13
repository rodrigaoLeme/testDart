class MenuItemEntity {
  final String id;
  final String title;
  final String icon;
  final String route;
  final bool isButton;

  MenuItemEntity({
    required this.id,
    required this.title,
    required this.icon,
    required this.route,
    this.isButton = false,
  });
}
