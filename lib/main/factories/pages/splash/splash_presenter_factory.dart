import '../../../../presentation/presenters/splash/stream_splash_presenter.dart';
import '../../../../ui/modules/splash/splash_presenter.dart';
import '../../services/dify_sync_service_factory.dart';
import '../../usecases/account/firebase_load_current_account_factory.dart';
import '../../usecases/chat/chat.dart';
import '../../usecases/faq/faq.dart';
import '../../usecases/suggestions/suggestions.dart';

SplashPresenter makeSplashPresenter() => StreamSplashPresenter(
      loadCurrentAccount: makeFirebaseLoadCurrentAccount(),
      loadFAQItems: makeLoadFAQItems(),
      loadSuggestions: makeLoadSuggestions(),
      loadConversations: makeLoadConversations(),
      difySyncService: makeDifySyncService(),
    );
