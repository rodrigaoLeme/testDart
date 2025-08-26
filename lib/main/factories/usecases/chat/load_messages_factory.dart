import '../../../../domain/usecases/chat/load_messages.dart';
import '../../adapters/dify_load_messages_adapter_factory.dart';

LoadMessages makeLoadMessages() => makeDifyLoadMessagesAdapter();
