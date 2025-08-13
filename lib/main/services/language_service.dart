import 'package:flutter/material.dart';

import '../../domain/usecases/usecases.dart';
import '../../ui/helpers/helpers.dart';

class LanguageService {
  static LanguageService? _instance;
  static LanguageService get instance => _instance ??= LanguageService._();
  LanguageService._();

  late LoadCurrentLanguage _loadCurrentLanguage;
  late SaveCurrentLanguage _saveCurrentLanguage;
  String? _currentLanguageCode;

  void initialize({
    required LoadCurrentLanguage loadCurrentLanguage,
    required SaveCurrentLanguage saveCurrentLanguage,
  }) {
    _loadCurrentLanguage = loadCurrentLanguage;
    _saveCurrentLanguage = saveCurrentLanguage;
  }

  Future<void> loadInitialLanguage() async {
    try {
      final languageEntity = await _loadCurrentLanguage.load();
      _currentLanguageCode = languageEntity.code;

      Locale locale = _getLocaleFromCode(languageEntity.code);
      R.load(locale);
    } catch (error) {
      _currentLanguageCode = 'en';
      R.load(const Locale('en'));
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    try {
      await _saveCurrentLanguage.save(languageCode);
      _currentLanguageCode = languageCode;

      Locale locale = _getLocaleFromCode(languageCode);
      R.load(locale);
    } catch (_) {}
  }

  String get currentLanguageCode => _currentLanguageCode ?? 'en';

  Locale _getLocaleFromCode(String code) {
    switch (code) {
      case 'pt_BR':
        return const Locale('pt', 'BR');
      case 'es':
        return const Locale('es');
      default:
        return const Locale('en');
    }
  }
}
