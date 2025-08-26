import '../../../data/services/dify_sync_service.dart';
import '../clients/dify_api_client_factory.dart';
import '../repositories/dify_chat_repository_factory.dart';
import '../usecases/user/firebase_load_current_user_factory.dart';

DifySyncService makeDifySyncService() => DifySyncService(
      difyApiClient: makeDifyApiClient(),
      difyChatRepository: makeDifyChatRepository(),
      loadCurrentUser: makeFirebaseLoadCurrentUser(),
    );
