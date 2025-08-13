import '../../../domain/usecases/usecases.dart';
import '../../../infra/cache/cache.dart';
import '../../../domain/helpers/helpers.dart';

class FirebaseDeleteCurrentAccount implements DeleteCurrentAccount {
  final SecureStorageAdapter secureStorage;

  FirebaseDeleteCurrentAccount({required this.secureStorage});

  @override
  Future<void> delete() async {
    try {
      await secureStorage.delete(SecureStorageKey.account);
    } catch (_) {
      throw DomainError.unexpected;
    }
  }
}
