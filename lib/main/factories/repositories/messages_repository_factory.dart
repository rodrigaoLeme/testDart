import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/repositories/messages_repository.dart';
import '../cache/shared_preferences_storage_adapter_factory.dart';

MessagesRepository makeMessagesRepository() => MessagesRepository(
      firestore: FirebaseFirestore.instance,
      localStorage: makeSharedPreferencesStorageAdapter(),
    );
