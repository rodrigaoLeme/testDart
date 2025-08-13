abstract class SaveUserToFirestore {
  Future<void> save({
    required String uid,
    required String email,
    required String displayName,
    String? photoURL,
    required String provider,
  });
}
