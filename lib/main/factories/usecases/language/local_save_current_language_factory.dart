import '../../../../data/usecases/language/language.dart';
import '../../../../domain/usecases/language/language.dart';
import '../../cache/shared_preferences_storage_adapter_factory.dart';

SaveCurrentLanguage makeLocalSaveCurrentLanguage() => LocalSaveCurrentLanguage(
      localStorage: makeSharedPreferencesStorageAdapter(),
    );
