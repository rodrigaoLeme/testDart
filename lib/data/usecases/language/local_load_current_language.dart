import '../../../domain/entities/entities.dart';
import '../../../domain/helpers/helpers.dart';
import '../../../domain/usecases/language/get_device_language.dart';
import '../../../domain/usecases/language/load_current_language.dart';
import '../../../infra/cache/cache.dart';

class LocalLoadCurrentLanguage implements LoadCurrentLanguage {
  final SharedPreferencesStorageAdapter localStorage;
  final GetDeviceLanguage getDeviceLanguage;

  LocalLoadCurrentLanguage({
    required this.localStorage,
    required this.getDeviceLanguage,
  });

  @override
  Future<LanguageEntity> load() async {
    try {
      final savedLanguageCode = await localStorage.fetch('user_language');

      String languageCode;
      if (savedLanguageCode != null && savedLanguageCode.isNotEmpty) {
        languageCode = savedLanguageCode;
      } else {
        languageCode = getDeviceLanguage.deviceLanguageCode;
        await localStorage.save(key: 'user_language', value: languageCode);
      }

      if (!_isSupportedLanguage(languageCode)) {
        languageCode = 'en';
        await localStorage.save(key: 'user_language', value: languageCode);
      }

      return _buildLanguageEntity(languageCode);
    } catch (_) {
      throw DomainError.unexpected;
    }
  }

  bool _isSupportedLanguage(String code) {
    return ['en', 'pt_BR', 'es'].contains(code);
  }

  LanguageEntity _buildLanguageEntity(String code) {
    switch (code) {
      case 'pt_BR':
        return LanguageEntity(
          code: 'pt_BR',
          name: 'Português',
          flag: 'lib/ui/assets/images/countries/br.png',
          isSelected: true,
        );
      case 'es':
        return LanguageEntity(
          code: 'es',
          name: 'Español',
          flag: 'lib/ui/assets/images/countries/es.png',
          isSelected: true,
        );
      default: // 'en'
        return LanguageEntity(
          code: 'en',
          name: 'English',
          flag: 'lib/ui/assets/images/countries/en.png',
          isSelected: true,
        );
    }
  }
}
