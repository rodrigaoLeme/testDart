import '../../../domain/helpers/helpers.dart';
import '../../../domain/usecases/user/update_user_language.dart';
import '../../repositories/firestore_user_repository.dart';

class FirestoreUpdateUserLanguage implements UpdateUserLanguage {
  final FirestoreUserRepository repository;

  FirestoreUpdateUserLanguage({required this.repository});

  @override
  Future<void> update(String uid, String language) async {
    try {
      String firestoreLanguage;
      switch (language) {
        case 'pt_BR':
          firestoreLanguage = 'pt';
          break;
        case 'es':
          firestoreLanguage = 'es';
          break;
        default:
          firestoreLanguage = 'en';
          break;
      }

      await repository.updateUserLanguage(uid, firestoreLanguage);
    } catch (_) {
      throw DomainError.unexpected;
    }
  }
}
