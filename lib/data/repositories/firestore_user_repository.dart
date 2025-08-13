import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/entities.dart';
import '../../domain/helpers/helpers.dart';
import '../models/users/firestore_user_model.dart';

class FirestoreUserRepository {
  final FirebaseFirestore firestore;

  FirestoreUserRepository({required this.firestore});

  Future<void> saveOrUpdateUser({
    required String uid,
    required String email,
    required String displayName,
    String? photoURL,
    required String provider,
  }) async {
    try {
      final userDoc = firestore.collection('users').doc(uid);
      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        // Usuário já existe, atualiza apenas lastLogin e language
        final userModel = FirestoreUserModel.fromFirebaseUser(
          uid: uid,
          email: email,
          displayName: displayName,
          photoURL: photoURL,
          provider: provider,
          isNewUser: false,
        );

        final updateData = userModel.toFirestoreUpdate();
        await userDoc.update(updateData);
      } else {
        // Novo usuário
        final userModel = FirestoreUserModel.fromFirebaseUser(
          uid: uid,
          email: email,
          displayName: displayName,
          photoURL: photoURL,
          provider: provider,
          isNewUser: true,
        );

        final userData = userModel.toFirestore();
        await userDoc.set(userData);
      }
    } catch (error) {
      throw DomainError.unexpected;
    }
  }

  Future<FirestoreUserEntity?> getUser(String uid) async {
    try {
      final userDoc = await firestore.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final userModel = FirestoreUserModel.fromFirestore(userDoc.data()!);
        return userModel.toEntity();
      }

      return null;
    } catch (error) {
      throw DomainError.unexpected;
    }
  }

  Future<void> updateUserLanguage(String uid, String language) async {
    try {
      await firestore.collection('users').doc(uid).update({
        'language': language,
        'lastLogin': DateTime.now(),
      });
    } catch (error) {
      throw DomainError.unexpected;
    }
  }
}
