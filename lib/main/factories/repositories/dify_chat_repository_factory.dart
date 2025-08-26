import '../../../data/repositories/dify_chat_repository.dart';
import '../cache/shared_preferences_storage_adapter_factory.dart';
import '../clients/dify_api_client_factory.dart';
import '../services/dify_service_factory.dart';
import '../usecases/user/firebase_load_current_user_factory.dart';

DifyChatRepository makeDifyChatRepository() => DifyChatRepository(
      difyApiClient: makeDifyApiClient(),
      difyService: makeDifyService(),
      localStorage: makeSharedPreferencesStorageAdapter(),
      loadCurrentUser: makeFirebaseLoadCurrentUser(),
    );
