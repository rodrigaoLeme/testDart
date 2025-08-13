import '../../../domain/entities/entities.dart';
import '../../../domain/helpers/helpers.dart';
import '../../../domain/usecases/usecases.dart';
import '../../../infra/cache/cache.dart';
import '../../models/account/firebase_account_model.dart';

class FirebaseLoadCurrentAccount implements LoadCurrentAccount {
  final SecureStorageAdapter secureStorage;

  FirebaseLoadCurrentAccount({required this.secureStorage});

  @override
  Future<AccountEntity?> load() async {
    try {
      final json = await secureStorage.fetch(SecureStorageKey.account);
      if (json == null) return null;
      return FirebaseAccountModel.fromString(json).toEntity();
    } catch (_) {
      throw DomainError.unexpected;
    }
  }
}
