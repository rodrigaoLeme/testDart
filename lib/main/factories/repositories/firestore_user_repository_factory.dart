import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/repositories/firestore_user_repository.dart';

FirestoreUserRepository makeFirestoreUserRepository() =>
    FirestoreUserRepository(
      firestore: FirebaseFirestore.instance,
    );
