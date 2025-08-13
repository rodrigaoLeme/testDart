import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/repositories/chat_repository.dart';
import '../cache/shared_preferences_storage_adapter_factory.dart';
import '../usecases/user/firebase_load_current_user_factory.dart';
import './messages_repository_factory.dart';

ChatRepository makeChatRepository() => ChatRepository(
      firestore: FirebaseFirestore.instance,
      localStorage: makeSharedPreferencesStorageAdapter(),
      messagesRepository: makeMessagesRepository(),
      loadCurrentUser: makeFirebaseLoadCurrentUser(),
    );
