import '../../../domain/entities/entities.dart';
import '../../../main/services/language_service.dart';

class FirestoreUserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String provider;
  final String language;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime lastLogin;

  FirestoreUserModel({
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

  factory FirestoreUserModel.fromFirebaseUser({
    required String uid,
    required String email,
    required String displayName,
    String? photoURL,
    required String provider,
    bool isNewUser = false,
  }) {
    final now = DateTime.now();
    final currentLanguage = LanguageService.instance.currentLanguageCode;

    String firestoreLanguage;
    switch (currentLanguage) {
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

    return FirestoreUserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      provider: provider,
      language: firestoreLanguage,
      isAdmin: false,
      createdAt: isNewUser ? now : now,
      lastLogin: now,
    );
  }

  factory FirestoreUserModel.fromFirestore(Map<String, dynamic> data) {
    return FirestoreUserModel(
      uid: data['uid'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      photoURL: data['photoURL'] as String?,
      provider: data['provider'] as String,
      language: data['language'] as String? ?? 'en',
      isAdmin: data['isAdmin'] as bool? ?? false,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      lastLogin: (data['lastLogin'] as dynamic).toDate(),
    );
  }

  FirestoreUserEntity toEntity() {
    return FirestoreUserEntity(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      provider: provider,
      language: language,
      isAdmin: isAdmin,
      createdAt: createdAt,
      lastLogin: lastLogin,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'provider': provider,
      'language': language,
      'isAdmin': isAdmin,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }

  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'lastLogin': lastLogin,
      'language': language,
    };
  }
}
