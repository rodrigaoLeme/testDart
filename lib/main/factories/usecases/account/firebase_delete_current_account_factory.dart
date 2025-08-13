import '../../../../data/usecases/account/firebase_delete_current_account.dart';
import '../../../../domain/usecases/usecases.dart';
import '../../cache/secure_storage_adapter_factory.dart';

DeleteCurrentAccount makeFirebaseDeleteCurrentAccount() =>
    FirebaseDeleteCurrentAccount(
      secureStorage: makeSecureStorageAdapter(),
    );
