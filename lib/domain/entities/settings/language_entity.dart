class LanguageEntity {
  final String code;
  final String name;
  final String flag;
  final bool isSelected;

  LanguageEntity({
    required this.code,
    required this.name,
    required this.flag,
    this.isSelected = false,
  });

  LanguageEntity copyWith({bool? isSelected}) {
    return LanguageEntity(
      code: code,
      name: name,
      flag: flag,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
