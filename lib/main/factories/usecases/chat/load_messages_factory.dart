import '../../../../domain/usecases/chat/load_messages.dart';
import '../../repositories/messages_repository_factory.dart';

LoadMessages makeLoadMessages() => makeMessagesRepository();
