import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../domain/entities/entities.dart';

class FirebaseAccountModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? providerId;

  FirebaseAccountModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.providerId,
  });

  factory FirebaseAccountModel.fromUser(User user) {
    String? provider = 'email';
    if (user.providerData.isNotEmpty) {
      final providerId = user.providerData.first.providerId;
      switch (providerId) {
        case 'google.com':
          provider = 'google';
          break;
        case 'apple.com':
          provider = 'apple';
          break;
        case 'facebook.com':
          provider = 'facebook';
          break;
        default:
          provider = providerId;
      }
    }

    return FirebaseAccountModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      providerId: provider,
    );
  }

  factory FirebaseAccountModel.fromUserWithFallback(
    User user, {
    GoogleSignInAccount? googleUser,
  }) {
    String? provider = 'email';
    if (user.providerData.isNotEmpty) {
      final providerId = user.providerData.first.providerId;
      switch (providerId) {
        case 'google.com':
          provider = 'google';
          break;
        case 'apple.com':
          provider = 'apple';
          break;
        case 'facebook.com':
          provider = 'facebook';
          break;
        default:
          provider = providerId;
      }
    }

    return FirebaseAccountModel(
      uid: user.uid,
      email: user.email ?? googleUser?.email,
      // ✅ Fallback: Firebase displayName ou Google displayName
      displayName: user.displayName ?? googleUser?.displayName,
      // ✅ Fallback: Firebase photoURL ou Google photoUrl
      photoUrl: user.photoURL ?? googleUser?.photoUrl,
      providerId: provider,
    );
  }

  factory FirebaseAccountModel.fromEntity(AccountEntity entity) {
    return FirebaseAccountModel(
      uid: entity.dataProfile.token,
      email: null,
      displayName: null,
      photoUrl: null,
      providerId: null,
    );
  }

  AccountEntity toEntity() {
    return AccountEntity(
      success: true,
      message: 'Usuário autenticado',
      statusCode: 200,
      dataProfile: AccountDataEntity(
        id: uid.hashCode,
        token: uid,
      ),
    );
  }

  UserEntity toUserEntity() {
    return UserEntity(
      id: uid,
      name: displayName ?? email?.split('@').first ?? 'Usuário',
      email: email ?? '',
      photoUrl: photoUrl,
      provider: providerId ?? 'email',
    );
  }

  factory FirebaseAccountModel.fromJson(Map<String, dynamic> json) {
    return FirebaseAccountModel(
      uid: json['uid'] ?? '',
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      providerId: json['providerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'providerId': providerId,
    };
  }

  factory FirebaseAccountModel.fromString(String source) {
    final Map<String, dynamic> json = jsonDecode(source);
    return FirebaseAccountModel.fromJson(json);
  }

  String toStringify() {
    return jsonEncode(toJson());
  }
}
