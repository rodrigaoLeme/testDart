import 'dart:convert';

import '../../../domain/entities/suggestions/suggestion_entity.dart';
import '../../../main/services/language_service.dart';
import './suggestion_translation.dart';

class SuggestionModel {
  final String id;
  final int order;
  final bool active;
  final DateTime createdAt;
  final Map<String, SuggestionTranslation> translations;

  SuggestionModel({
    required this.id,
    required this.order,
    required this.active,
    required this.createdAt,
    required this.translations,
  });

  factory SuggestionModel.fromFirestore(Map<String, dynamic> data) {
    final translationsMap = data['translations'] as Map<String, dynamic>;
    final translations = <String, SuggestionTranslation>{};

    translationsMap.forEach((language, content) {
      final contentMap = content as Map<String, dynamic>;
      translations[language] = SuggestionTranslation(
        text: contentMap['text'] as String,
      );
    });

    return SuggestionModel(
      id: data['id'] as String,
      order: data['order'] as int,
      active: data['active'] as bool? ?? true,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      translations: translations,
    );
  }

  factory SuggestionModel.fromCache(Map<String, dynamic> json) {
    final translationsMap = json['translations'] as Map<String, dynamic>;
    final translations = <String, SuggestionTranslation>{};

    translationsMap.forEach((language, content) {
      final contentMap = content as Map<String, dynamic>;
      translations[language] = SuggestionTranslation(
        text: contentMap['text'] as String,
      );
    });

    return SuggestionModel(
      id: json['id'] as String,
      order: json['order'] as int,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      translations: translations,
    );
  }

  SuggestionEntity toEntity({String? forceLanguage}) {
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

    return SuggestionEntity(
      id: id,
      order: order,
      active: active,
      createdAt: createdAt,
      text: translation.text,
    );
  }

  Map<String, dynamic> toCache() {
    final translationsMap = <String, dynamic>{};
    translations.forEach((language, translation) {
      translationsMap[language] = {
        'text': translation.text,
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

  static List<SuggestionModel> fromCacheString(String cacheString) {
    final List<dynamic> jsonList = jsonDecode(cacheString);
    return jsonList.map((json) => SuggestionModel.fromCache(json)).toList();
  }

  static String listToCacheString(List<SuggestionModel> items) {
    final jsonList = items.map((item) => item.toCache()).toList();
    return jsonEncode(jsonList);
  }
}
