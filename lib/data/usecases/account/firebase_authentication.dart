import '../../../domain/entities/account/account_entity.dart';

abstract class FirebaseAuthentication {
  Future<AccountEntity> signInWithGoogle();
  Future<AccountEntity> signInWithApple();
  Future<AccountEntity> signInWithMicrosoft();
  Future<AccountEntity> signInWithFacebook();
}
