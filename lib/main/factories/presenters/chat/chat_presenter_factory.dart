import '../../../../presentation/presenters/chat/chat_presenter.dart';
import '../../../../presentation/presenters/chat/stream_chat_presenter.dart';
import '../../repositories/dify_chat_repository_factory.dart';
import '../../usecases/chat/chat.dart';
import '../../usecases/user/firebase_load_current_user_factory.dart';

ChatPresenter makeChatPresenter() => StreamChatPresenter(
      loadCurrentUser: makeFirebaseLoadCurrentUser(),
      createConversation: makeCreateConversation(),
      loadMessages: makeLoadMessages(),
      sendMessage: makeSendMessage(),
      sendToDify: makeSendToDify(),
      updateConversation: makeUpdateConversation(),
      difyChatRepository: makeDifyChatRepository(),
    );
