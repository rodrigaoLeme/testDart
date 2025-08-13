import '../../../domain/entities/entities.dart';
import '../../../domain/helpers/helpers.dart';
import '../../../domain/usecases/user/user.dart';
import '../../repositories/firestore_user_repository.dart';

class FirestoreLoadUser implements LoadUserFromFirestore {
  final FirestoreUserRepository repository;

  FirestoreLoadUser({required this.repository});

  @override
  Future<FirestoreUserEntity?> load(String uid) async {
    try {
      return await repository.getUser(uid);
    } catch (_) {
      throw DomainError.unexpected;
    }
  }
}
