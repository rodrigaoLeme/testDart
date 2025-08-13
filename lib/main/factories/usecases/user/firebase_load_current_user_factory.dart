import '../../../../data/usecases/user/firebase_load_current_user.dart';
import '../../../../domain/usecases/usecases.dart';
import '../../cache/secure_storage_adapter_factory.dart';

LoadCurrentUser makeFirebaseLoadCurrentUser() => FirebaseLoadCurrentUser(
      secureStorage: makeSecureStorageAdapter(),
    );
