import 'dart:convert';

import '../../../domain/entities/entities.dart';

class FAQMetadataModel {
  final String version;
  final DateTime lastUpdated;
  final int totalItems;

  FAQMetadataModel({
    required this.version,
    required this.lastUpdated,
    required this.totalItems,
  });

  factory FAQMetadataModel.fromFirestore(Map<String, dynamic> data) {
    return FAQMetadataModel(
      version: data['version'] as String,
      lastUpdated: (data['lastUpdated'] as dynamic).toDate(),
      totalItems: data['totalItems'] as int,
    );
  }

  factory FAQMetadataModel.fromCache(Map<String, dynamic> json) {
    return FAQMetadataModel(
      version: json['version'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      totalItems: json['totalItems'] as int,
    );
  }

  FAQMetadataEntity toEntity() {
    return FAQMetadataEntity(
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

  factory FAQMetadataModel.fromCacheString(String cacheString) {
    final Map<String, dynamic> json = jsonDecode(cacheString);
    return FAQMetadataModel.fromCache(json);
  }
}
