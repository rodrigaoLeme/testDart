class FirestoreUserEntity {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String provider;
  final String language;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime lastLogin;

  FirestoreUserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.provider,
    required this.language,
    required this.isAdmin,
    required this.createdAt,
    required this.lastLogin,
  });
}
