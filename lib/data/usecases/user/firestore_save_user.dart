import '../../../domain/helpers/helpers.dart';
import '../../../domain/usecases/usecases.dart';
import '../../repositories/firestore_user_repository.dart';

class FirestoreSaveUser implements SaveUserToFirestore {
  final FirestoreUserRepository repository;

  FirestoreSaveUser({required this.repository});

  @override
  Future<void> save({
    required String uid,
    required String email,
    required String displayName,
    String? photoURL,
    required String provider,
  }) async {
    try {
      await repository.saveOrUpdateUser(
        uid: uid,
        email: email,
        displayName: displayName,
        photoURL: photoURL,
        provider: provider,
      );
    } catch (_) {
      throw DomainError.unexpected;
    }
  }
}
