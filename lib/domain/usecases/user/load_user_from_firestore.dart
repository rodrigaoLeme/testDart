import '../../entities/entities.dart';

abstract class LoadUserFromFirestore {
  Future<FirestoreUserEntity?> load(String uid);
}
