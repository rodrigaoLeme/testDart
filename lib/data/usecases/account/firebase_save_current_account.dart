import '../../../domain/usecases/usecases.dart';
import '../../../infra/cache/cache.dart';
import '../../../domain/helpers/helpers.dart';

class FirebaseSaveCurrentAccount implements SaveCurrentAccount {
  final SecureStorageAdapter secureStorage;

  FirebaseSaveCurrentAccount({required this.secureStorage});

  @override
  Future<void> save(String accountJson) async {
    try {
      await secureStorage.save(
        key: SecureStorageKey.account,
        value: accountJson,
      );
    } catch (_) {
      throw DomainError.unexpected;
    }
  }
}
