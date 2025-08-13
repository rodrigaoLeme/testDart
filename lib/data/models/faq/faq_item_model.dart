import 'dart:convert';

import '../../../domain/entities/entities.dart';
import '../../../main/services/language_service.dart';
import './faq.dart';

class FAQItemModel {
  final String id;
  final int order;
  final bool active;
  final DateTime createdAt;
  final Map<String, FAQTranslation> translations;

  FAQItemModel({
    required this.id,
    required this.order,
    required this.active,
    required this.createdAt,
    required this.translations,
  });

  factory FAQItemModel.fromFirestore(Map<String, dynamic> data) {
    final translationsMap = data['translations'] as Map<String, dynamic>;
    final translations = <String, FAQTranslation>{};

    translationsMap.forEach((language, content) {
      final contentMap = content as Map<String, dynamic>;
      translations[language] = FAQTranslation(
        title: contentMap['title'] as String,
        description: contentMap['description'] as String,
      );
    });

    return FAQItemModel(
      id: data['id'] as String,
      order: data['order'] as int,
      active: data['active'] as bool? ?? true,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      translations: translations,
    );
  }

  factory FAQItemModel.fromCache(Map<String, dynamic> json) {
    final translationsMap = json['translations'] as Map<String, dynamic>;
    final translations = <String, FAQTranslation>{};

    translationsMap.forEach((language, content) {
      final contentMap = content as Map<String, dynamic>;
      translations[language] = FAQTranslation(
        title: contentMap['title'] as String,
        description: contentMap['description'] as String,
      );
    });

    return FAQItemModel(
      id: json['id'] as String,
      order: json['order'] as int,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      translations: translations,
    );
  }

  FAQItemEntity toEntity({String? forceLanguage}) {
    // Usa idioma forçado ou pega do serviço
    final currentLanguage =
        forceLanguage ?? LanguageService.instance.currentLanguageCode;

    String firebaseLanguageKey;
    switch (currentLanguage) {
      case 'pt_BR':
        firebaseLanguageKey = 'PT';
        break;
      case 'es':
        firebaseLanguageKey = 'ES';
        break;
      case 'en':
      default:
        firebaseLanguageKey = 'EN';
        break;
    }

    // Se idioma está vazio, força inglês
    if (currentLanguage.isEmpty) {
      firebaseLanguageKey = 'EN';
    }

    final translation = translations[firebaseLanguageKey] ??
        translations['EN'] ??
        translations.values.first;

    return FAQItemEntity(
      id: id,
      order: order,
      active: active,
      createdAt: createdAt,
      title: translation.title,
      description: translation.description,
    );
  }

  Map<String, dynamic> toCache() {
    final translationsMap = <String, dynamic>{};
    translations.forEach((language, translation) {
      translationsMap[language] = {
        'title': translation.title,
        'description': translation.description,
      };
    });

    return {
      'id': id,
      'order': order,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'translations': translationsMap,
    };
  }

  String toCacheString() => jsonEncode(toCache());

  static List<FAQItemModel> fromCacheString(String cacheString) {
    final List<dynamic> jsonList = jsonDecode(cacheString);
    return jsonList.map((json) => FAQItemModel.fromCache(json)).toList();
  }

  static String listToCacheString(List<FAQItemModel> items) {
    final jsonList = items.map((item) => item.toCache()).toList();
    return jsonEncode(jsonList);
  }
}
