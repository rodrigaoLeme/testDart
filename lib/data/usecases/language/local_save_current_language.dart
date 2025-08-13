import '../../../domain/helpers/helpers.dart';
import '../../../domain/usecases/language/save_current_language.dart';
import '../../../infra/cache/cache.dart';

class LocalSaveCurrentLanguage implements SaveCurrentLanguage {
  final SharedPreferencesStorageAdapter localStorage;

  LocalSaveCurrentLanguage({required this.localStorage});

  @override
  Future<void> save(String languageCode) async {
    try {
      await localStorage.save(key: 'user_language', value: languageCode);
    } catch (_) {
      throw DomainError.unexpected;
    }
  }
}
