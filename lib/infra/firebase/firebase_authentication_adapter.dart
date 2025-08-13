import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../data/models/account/firebase_account_model.dart';
import '../../data/usecases/account/firebase_authentication.dart';
import '../../domain/entities/entities.dart';
import '../../domain/helpers/helpers.dart';
import '../../domain/usecases/usecases.dart';
import '../../main/services/logger_service.dart';

class FirebaseAuthenticationAdapter implements FirebaseAuthentication {
  final FirebaseAuth firebaseAuth;
  final SaveCurrentAccount saveCurrentAccount;
  final SaveUserToFirestore saveUserToFirestore;

  FirebaseAuthenticationAdapter({
    required this.firebaseAuth,
    required this.saveCurrentAccount,
    required this.saveUserToFirestore,
  });

  @override
  Future<AccountEntity> signInWithGoogle() async {
    try {
      LoggerService.info('Iniciando login com Google', name: 'Auth');
      await GoogleSignIn.instance.initialize();

      GoogleSignInAccount? googleUser =
          await GoogleSignIn.instance.attemptLightweightAuthentication();

      googleUser ??= await GoogleSignIn.instance.authenticate(
        scopeHint: [
          'email',
          'profile',
        ],
      );
      LoggerService.debug('Google user obtido', name: 'Auth');

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw DomainError.configurationError;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await firebaseAuth.signInWithCredential(credential);
      final user = result.user!;

      LoggerService.info(
          'Login ${result.additionalUserInfo?.isNewUser == true ? "novo" : "existente"} realizado',
          name: 'Auth');

      LoggerService.debug('UID: ${user.uid}', name: 'AuthDebug');
      LoggerService.debug('Email: ${user.email}', name: 'AuthDebug');

      await _waitForAuthState(user.uid);

      final accountModel = FirebaseAccountModel.fromUserWithFallback(
        user,
        googleUser: googleUser,
      );

      // Salva no cache local
      await saveCurrentAccount.save(accountModel.toStringify());

      await Future.delayed(const Duration(milliseconds: 500));

      // Salva no Firestore
      await _saveUserToFirestore(accountModel, 'Google');

      // Analytics (sempre ativo)
      LoggerService.analytics('user_login', {
        'provider': 'google',
        'is_new_user': result.additionalUserInfo?.isNewUser,
      });

      LoggerService.info('Login Google concluído com sucesso', name: 'Auth');
      return accountModel.toEntity();
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase Auth Error: ${e.code}',
          name: 'Auth', error: e);
      throw _mapFirebaseError(e);
    } on PlatformException catch (e) {
      LoggerService.error('PlatformException: ${e.code}',
          name: 'FirebaseAuth', error: e);
      throw _mapPlatformError(e);
    } on GoogleSignInException catch (e) {
      LoggerService.error('GoogleSignInException: ${e.code} - ${e.description}',
          name: 'FirebaseAuth', error: e);
      throw _mapGoogleError(e);
    } catch (e, stackTrace) {
      LoggerService.error('Erro inesperado no login Google',
          name: 'Auth', error: e, stackTrace: stackTrace);
      throw DomainError.unexpected;
    }
  }

  DomainError _mapGoogleError(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return DomainError.authCancelled;
      case GoogleSignInExceptionCode.uiUnavailable:
        return DomainError.configurationError;
      case GoogleSignInExceptionCode.interrupted:
        return DomainError.authInProgress;
      default:
        return DomainError.unexpected;
    }
  }

  @override
  Future<AccountEntity> signInWithApple() async {
    try {
      LoggerService.info('Iniciando login com Apple', name: 'Auth');

      final result = await _signInWithProvider(AppleAuthProvider());
      final user = result.user!;

      // Log seguro - só mostra se é novo usuário
      LoggerService.info(
          'Login ${result.additionalUserInfo?.isNewUser == true ? "novo" : "existente"} realizado',
          name: 'Auth');

      // Dados sensíveis só em debug
      LoggerService.debug('UID: ${user.uid}', name: 'AuthDebug');
      LoggerService.debug('Email: ${user.email}', name: 'AuthDebug');

      final accountModel = FirebaseAccountModel.fromUser(user);

      // Salva no cache local
      await saveCurrentAccount.save(accountModel.toStringify());

      // Salva no Firestore
      await _saveUserToFirestore(accountModel, 'Apple');

      // Analytics (sempre ativo)
      LoggerService.analytics('user_login', {
        'provider': 'apple',
        'is_new_user': result.additionalUserInfo?.isNewUser,
      });

      return accountModel.toEntity();
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase Auth Error: ${e.code}',
          name: 'Auth', error: e);
      throw _mapFirebaseError(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      LoggerService.error('Sign In With Apple: ${e.code}',
          name: 'Auth', error: e);
      throw _mapAppleError(e);
    } catch (e, stackTrace) {
      LoggerService.error('Erro inesperado no login Apple',
          name: 'Auth', error: e, stackTrace: stackTrace);
      throw DomainError.unexpected;
    }
  }

  @override
  Future<AccountEntity> signInWithMicrosoft() async {
    try {
      final result = await _signInWithProvider(OAuthProvider('microsoft.com'));
      return FirebaseAccountModel.fromUser(result.user!).toEntity();
      // TODO @rodrigo.leme implementar erro customizado
    } catch (_) {
      throw DomainError.unexpected;
    }
  }

  Future<UserCredential> _signInWithProvider(AuthProvider provider) {
    return firebaseAuth.signInWithProvider(provider);
  }

  @override
  Future<AccountEntity> signInWithFacebook() async {
    try {
      LoggerService.info('Iniciando login com Facebook', name: 'Auth');
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {}

      switch (result.status) {
        case LoginStatus.success:
          final OAuthCredential credential =
              FacebookAuthProvider.credential(result.accessToken!.tokenString);
          final UserCredential userCredential =
              await firebaseAuth.signInWithCredential(credential);

          final user = userCredential.user!;
          final accountModel = FirebaseAccountModel.fromUser(user);

          // Salva no cache local
          await saveCurrentAccount.save(accountModel.toStringify());

          // Salva no Firestore
          await _saveUserToFirestore(accountModel, 'Facebook');

          return accountModel.toEntity();
        case LoginStatus.cancelled:
          throw DomainError.authCancelled;
        case LoginStatus.failed:
          throw DomainError.accessDenied;
        case LoginStatus.operationInProgress:
          throw DomainError.authInProgress;
      }
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    } catch (e) {
      debugPrint('Facebook Sign-In Error: $e');
      if (e == DomainError.accessDenied) {
        throw DomainError.accessDenied;
      } else {
        throw DomainError.unexpected;
      }
    }
  }

  Future<void> _saveUserToFirestore(
      FirebaseAccountModel user, String provider) async {
    try {
      LoggerService.debug('Salvando usuário no Firestore', name: 'Firestore');

      await saveUserToFirestore.save(
        uid: user.uid,
        email: user.email ?? '',
        displayName:
            user.displayName ?? user.email?.split('@').first ?? 'Usuário',
        photoURL: user.photoUrl,
        provider: provider,
      );

      LoggerService.info('Usuário salvo no Firestore com sucesso',
          name: 'Firestore');
    } catch (error, stackTrace) {
      LoggerService.error('Erro ao salvar usuário no Firestore',
          name: 'Firestore', error: error, stackTrace: stackTrace);
      // erro não mexer se não quebra o login.
    }
  }

  DomainError _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-disabled':
        return DomainError.accountDisabled;
      case 'user-not-found':
      case 'wrong-password':
        return DomainError.invalidCredentials;
      case 'email-already-in-use':
        return DomainError.emailInUse;
      case 'network-request-failed':
        return DomainError.networkError;
      case 'too-many-requests':
        return DomainError.tooManyRequests;
      case 'operation-not-allowed':
        return DomainError.configurationError;
      case 'web-context-cancelled':
        return DomainError.webContextCancelled;
      default:
        debugPrint('Firebase Error Code: ${e.code} - ${e.message}');
        return DomainError.unexpected;
    }
  }

  DomainError _mapPlatformError(PlatformException e) {
    switch (e.code) {
      case 'sign_in_canceled':
      case 'ERROR_ABORTED_BY_USER':
        return DomainError.authCancelled;
      case 'network_error':
        return DomainError.networkError;
      default:
        debugPrint('Platform Error Code: ${e.code} - ${e.message}');
        return DomainError.unexpected;
    }
  }

  DomainError _mapAppleError(SignInWithAppleAuthorizationException e) {
    switch (e.code) {
      case AuthorizationErrorCode.canceled:
        return DomainError.authCancelled;
      case AuthorizationErrorCode.failed:
        return DomainError.accessDenied;
      case AuthorizationErrorCode.invalidResponse:
        return DomainError.configurationError;
      case AuthorizationErrorCode.notHandled:
        return DomainError.configurationError;
      case AuthorizationErrorCode.unknown:
      default:
        return DomainError.unexpected;
    }
  }

  // Aguarda o Firebase Auth estar completamente inicializado
  Future<User> _waitForAuthState(String expectedUid) async {
    const maxAttempts = 10;
    const delay = Duration(milliseconds: 500);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      final currentUser = firebaseAuth.currentUser;

      if (currentUser != null && currentUser.uid == expectedUid) {
        developer.log('✅ Auth state confirmado na tentativa $attempt',
            name: 'AuthWait');
        return currentUser;
      }

      developer.log(
          '⏳ Aguardando auth state... tentativa $attempt/$maxAttempts',
          name: 'AuthWait');

      if (attempt < maxAttempts) {
        await Future.delayed(delay);
      }
    }

    throw Exception(
        'Auth state não foi confirmado após $maxAttempts tentativas');
  }
}
