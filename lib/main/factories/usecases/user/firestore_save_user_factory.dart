import '../../../../data/usecases/user/firestore_save_user.dart';
import '../../../../domain/usecases/user/save_user_to_firestore.dart';
import '../../repositories/firestore_user_repository_factory.dart';

SaveUserToFirestore makeFirestoreSaveUser() => FirestoreSaveUser(
      repository: makeFirestoreUserRepository(),
    );
