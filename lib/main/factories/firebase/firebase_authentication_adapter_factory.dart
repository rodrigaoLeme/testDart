import 'package:firebase_auth/firebase_auth.dart';

import '../../../infra/firebase/firebase_authentication_adapter.dart';
import '../usecases/account/firebase_save_current_account_factory.dart';
import '../usecases/user/user.dart';

FirebaseAuthenticationAdapter makeFirebaseAuthenticationAdapter() =>
    FirebaseAuthenticationAdapter(
      firebaseAuth: FirebaseAuth.instance,
      saveCurrentAccount: makeFirebaseSaveCurrentAccount(),
      saveUserToFirestore: makeFirestoreSaveUser(),
    );
