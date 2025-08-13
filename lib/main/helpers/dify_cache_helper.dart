import '../../data/services/dify_service.dart';
import '../../domain/entities/chat/chat.dart';
import '../services/logger_service.dart';

class DifyCacheHelper {
  DifyCacheHelper._();

  // Limpa o cache de uma conversa específica
  static void clearConversation(String conversationId) {
    DifyService.clearConversationCache(conversationId);
    LoggerService.debug('Cache do Dify limpo para conversa: $conversationId',
        name: 'DifyCacheHelper');
  }

  // Limpa todo o cache (usado no logout)
  static void clearAll() {
    DifyService.clearAllConversationCache();
    LoggerService.debug('Todo cache do Dify foi limpo',
        name: 'DifyCacheHelper');
  }

  // Obtém informações do cache para debug
  static Map<String, String> getCache() {
    return DifyService.conversationCache;
  }

  // Verifica se uma conversa tem contexto no Dify
  static bool hasContext(String conversationId) {
    return DifyService.conversationCache.containsKey(conversationId);
  }

  static void printCache() {
    final cache = getCache();
    LoggerService.debug('Cache atual do Dify:', name: 'DifyCacheHelper');
    cache.forEach((local, dify) {
      LoggerService.debug('  $local -> $dify', name: 'DifyCacheHelper');
    });
  }

  static void printMessageStatuses(List<MessageEntity> messages) {
    LoggerService.debug('=== STATUS DAS MENSAGENS ===', name: 'MessageStatus');

    for (final message in messages) {
      final preview = message.content.length > 30
          ? '${message.content.substring(0, 30)}...'
          : message.content;

      LoggerService.debug(
        '${message.type.name}: "$preview" → ${message.status.name}',
        name: 'MessageStatus',
      );
    }

    final statusCount = <MessageStatus, int>{};
    for (final message in messages) {
      statusCount[message.status] = (statusCount[message.status] ?? 0) + 1;
    }

    LoggerService.debug('Resumo: $statusCount', name: 'MessageStatus');
  }
}
