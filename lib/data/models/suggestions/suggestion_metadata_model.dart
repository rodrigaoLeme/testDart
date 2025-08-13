import 'dart:convert';

import '../../../domain/entities/suggestions/suggestion_metadata_entity.dart';

class SuggestionMetadataModel {
  final String version;
  final DateTime lastUpdated;
  final int totalItems;

  SuggestionMetadataModel({
    required this.version,
    required this.lastUpdated,
    required this.totalItems,
  });

  factory SuggestionMetadataModel.fromFirestore(Map<String, dynamic> data) {
    return SuggestionMetadataModel(
      version: data['version'] as String,
      lastUpdated: (data['lastUpdated'] as dynamic).toDate(),
      totalItems: data['totalItems'] as int,
    );
  }

  factory SuggestionMetadataModel.fromCache(Map<String, dynamic> json) {
    return SuggestionMetadataModel(
      version: json['version'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      totalItems: json['totalItems'] as int,
    );
  }

  SuggestionMetadataEntity toEntity() {
    return SuggestionMetadataEntity(
      version: version,
      lastUpdated: lastUpdated,
      totalItems: totalItems,
    );
  }

  Map<String, dynamic> toCache() {
    return {
      'version': version,
      'lastUpdated': lastUpdated.toIso8601String(),
      'totalItems': totalItems,
    };
  }

  String toCacheString() => jsonEncode(toCache());

  factory SuggestionMetadataModel.fromCacheString(String cacheString) {
    final Map<String, dynamic> json = jsonDecode(cacheString);
    return SuggestionMetadataModel.fromCache(json);
  }
}
