import '../../../../data/usecases/user/firestore_update_user_language.dart';
import '../../../../domain/usecases/user/update_user_language.dart';
import '../../repositories/firestore_user_repository_factory.dart';

UpdateUserLanguage makeFirestoreUpdateUserLanguage() =>
    FirestoreUpdateUserLanguage(
      repository: makeFirestoreUserRepository(),
    );
