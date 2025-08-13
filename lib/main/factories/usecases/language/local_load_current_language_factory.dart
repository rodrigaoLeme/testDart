import '../../../../data/usecases/language/language.dart';
import '../../../../domain/usecases/language/language.dart';
import '../../cache/shared_preferences_storage_adapter_factory.dart';
import '../../device/device_language_adapter_factory.dart';

LoadCurrentLanguage makeLocalLoadCurrentLanguage() => LocalLoadCurrentLanguage(
      localStorage: makeSharedPreferencesStorageAdapter(),
      getDeviceLanguage: makeDeviceLanguageAdapter(),
    );
