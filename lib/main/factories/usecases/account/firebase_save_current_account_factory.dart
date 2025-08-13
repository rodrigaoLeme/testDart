import '../../../../data/usecases/account/firebase_save_current_account.dart';
import '../../../../domain/usecases/usecases.dart';
import '../../cache/secure_storage_adapter_factory.dart';

SaveCurrentAccount makeFirebaseSaveCurrentAccount() =>
    FirebaseSaveCurrentAccount(
      secureStorage: makeSecureStorageAdapter(),
    );
