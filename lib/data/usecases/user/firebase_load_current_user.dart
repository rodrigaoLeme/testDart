import '../../../domain/entities/entities.dart';
import '../../../domain/helpers/helpers.dart';
import '../../../domain/usecases/usecases.dart';
import '../../../infra/cache/cache.dart';
import '../../models/account/firebase_account_model.dart';

class FirebaseLoadCurrentUser implements LoadCurrentUser {
  final SecureStorageAdapter secureStorage;

  FirebaseLoadCurrentUser({required this.secureStorage});

  @override
  Future<UserEntity?> load() async {
    try {
      final json = await secureStorage.fetch(SecureStorageKey.account);
      if (json == null) return null;

      final accountModel = FirebaseAccountModel.fromString(json);
      return accountModel.toUserEntity();
    } catch (_) {
      throw DomainError.unexpected;
    }
  }
}
