import '../../../../presentation/presenters/home/home_presenter.dart';
import '../../../../presentation/presenters/home/stream_home_presenter.dart';
import '../../presenters/suggestions/suggestions_presenter_factory.dart';
import '../../usecases/chat/load_conversations_factory.dart';
import '../../usecases/user/firebase_load_current_user_factory.dart';

HomePresenter makeHomePresenter() => StreamHomePresenter(
      loadCurrentUserUseCase: makeFirebaseLoadCurrentUser(),
      suggestionsPresenter: makeSuggestionsPresenter(),
      loadConversations: makeLoadConversations(),
    );
