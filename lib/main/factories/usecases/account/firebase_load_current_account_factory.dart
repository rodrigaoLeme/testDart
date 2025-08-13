import '../../../../data/usecases/account/firebase_load_current_account.dart';
import '../../../../domain/usecases/usecases.dart';
import '../../cache/secure_storage_adapter_factory.dart';

LoadCurrentAccount makeFirebaseLoadCurrentAccount() =>
    FirebaseLoadCurrentAccount(
      secureStorage: makeSecureStorageAdapter(),
    );
