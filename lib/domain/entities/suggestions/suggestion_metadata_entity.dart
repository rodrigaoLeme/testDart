class SuggestionMetadataEntity {
  final String version;
  final DateTime lastUpdated;
  final int totalItems;

  SuggestionMetadataEntity({
    required this.version,
    required this.lastUpdated,
    required this.totalItems,
  });
}
