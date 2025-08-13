import '../../../../data/usecases/user/firestore_load_user.dart';
import '../../../../domain/usecases/user/load_user_from_firestore.dart';
import '../../repositories/firestore_user_repository_factory.dart';

LoadUserFromFirestore makeFirestoreLoadUser() => FirestoreLoadUser(
      repository: makeFirestoreUserRepository(),
    );
