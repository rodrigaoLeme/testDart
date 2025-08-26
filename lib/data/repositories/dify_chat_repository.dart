import '../../domain/entities/chat/chat.dart';
import '../../domain/helpers/helpers.dart';
import '../../domain/usecases/usecases.dart';
import '../../infra/cache/cache.dart';
import '../../main/services/logger_service.dart';
import '../adapters/dify_conversation_adapter.dart';
import '../adapters/dify_message_adapter.dart';
import '../clients/dify_api_client.dart';
import '../models/chat/conversation_model.dart';
import '../models/chat/message_model.dart';
import '../services/dify_service.dart';

/// Repository que usa Dify como backend ao invés do Firestore
class DifyChatRepository
    implements
        LoadConversations,
        CreateConversation,
        SendMessage,
        UpdateConversation,
        DeleteConversation,
        SyncConversations {
  // REMOVER LoadMessages daqui
  final DifyApiClient difyApiClient;
  final DifyService difyService; // Para envio de mensagens (já implementado)
  final SharedPreferencesStorageAdapter localStorage;
  final LoadCurrentUser _loadCurrentUser;

  static const String _conversationsKey = 'dify_conversations_cache';
  static const String _lastSyncKey = 'dify_conversations_last_sync';
  static const String _messagesPrefix = 'dify_messages_cache_';

  DifyChatRepository({
    required this.difyApiClient,
    required this.difyService,
    required this.localStorage,
    required LoadCurrentUser loadCurrentUser,
  }) : _loadCurrentUser = loadCurrentUser;

  // LOAD CONVERSATIONS (implementa LoadConversations)
  @override
  Future<List<ConversationEntity>> load({
    int limit = 20,
    String? startAfter,
  }) async {
    try {
      LoggerService.debug(
        'DifyChatRepository: Carregando conversas (limit: $limit)',
        name: 'DifyChatRepository',
      );

      // Tenta carregar do cache primeiro
      final cachedConversations = await _loadConversationsFromCache();
      if (cachedConversations.isNotEmpty) {
        LoggerService.debug(
          'Conversas carregadas do cache: ${cachedConversations.length}',
          name: 'DifyChatRepository',
        );

        return cachedConversations
            .map((model) => model.toEntity())
            .take(limit)
            .toList();
      }

      // Se não há cache, busca do Dify
      LoggerService.debug(
        'Cache vazio, sincronizando com Dify...',
        name: 'DifyChatRepository',
      );
      return await sync();
    } catch (error) {
      LoggerService.error(
        'Erro ao carregar conversas: $error',
        name: 'DifyChatRepository',
      );
      throw DomainError.unexpected;
    }
  }

  // CREATE CONVERSATION - Versão atualizada para criar após resposta do Dify
  @override
  Future<ConversationEntity> create({
    required String userId,
    required String firstMessage,
  }) async {
    // NOTA: Este método agora só deve ser chamado DEPOIS de receber resposta do Dify
    // O fluxo correto é: enviar mensagem → receber resposta → criar conversa
    throw UnimplementedError(
        'Use createConversationFromDifyResponse() após receber resposta do Dify');
  }

  /// Cria conversa após receber resposta do Dify (método novo)
  Future<ConversationEntity> createConversationFromDifyResponse({
    required String userId,
    required String difyConversationId,
    required String difyTitle,
    required String firstMessage,
    required String difyResponse,
  }) async {
    try {
      LoggerService.debug(
        'DifyChatRepository: Criando conversa com dados do Dify: $difyConversationId',
        name: 'DifyChatRepository',
      );

      // Cria conversa com dados reais do Dify
      final conversationModel = ConversationModel(
        id: difyConversationId, // Usa ID do Dify
        userId: userId,
        title: difyTitle, // Usa título gerado pelo Dify
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messageCount: 2, // User message + assistant response
        isActive: true,
        lastMessage: _truncateMessage(difyResponse),
        messages: [], // Mensagens são gerenciadas separadamente
      );

      // Atualiza cache local
      await _addConversationToCache(conversationModel);

      LoggerService.debug(
        'Conversa criada com dados do Dify: ${conversationModel.id}',
        name: 'DifyChatRepository',
      );

      return conversationModel.toEntity();
    } catch (error) {
      LoggerService.error(
        'Erro ao criar conversa com dados do Dify: $error',
        name: 'DifyChatRepository',
      );
      throw DomainError.unexpected;
    }
  }

  // SEND MESSAGE (usa DifyService existente)
  @override
  Future<MessageEntity> send({
    required String conversationId,
    required String content,
    required MessageType type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      LoggerService.debug(
        'DifyChatRepository: Enviando mensagem para conversa: $conversationId',
        name: 'DifyChatRepository',
      );

      final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
      final messageModel = MessageModel(
        id: messageId,
        conversationId: conversationId,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        metadata: metadata ?? {},
      );

      // Salva no cache local imediatamente (UX)
      await _addMessageToCache(conversationId, messageModel);

      // Nota: O envio real para o Dify é feito pelo DifyService no presenter
      // Este método apenas salva localmente para UX imediata

      LoggerService.debug(
        'Mensagem salva localmente: $messageId',
        name: 'DifyChatRepository',
      );

      return messageModel.toEntity();
    } catch (error) {
      LoggerService.error(
        'Erro ao enviar mensagem: $error',
        name: 'DifyChatRepository',
      );
      throw DomainError.unexpected;
    }
  }

  // UPDATE CONVERSATION
  @override
  Future<ConversationEntity> update(ConversationEntity conversation) async {
    try {
      LoggerService.debug(
        'DifyChatRepository: Atualizando conversa: ${conversation.id}',
        name: 'DifyChatRepository',
      );

      final model = ConversationModel.fromEntity(conversation);

      // No Dify, não há endpoint para atualizar conversa diretamente
      // Apenas atualiza o cache local
      await _updateConversationInCache(model);

      LoggerService.debug(
        'Conversa atualizada no cache: ${conversation.id}',
        name: 'DifyChatRepository',
      );

      return conversation;
    } catch (error) {
      LoggerService.error(
        'Erro ao atualizar conversa: $error',
        name: 'DifyChatRepository',
      );
      throw DomainError.unexpected;
    }
  }

  // DELETE CONVERSATION
  @override
  Future<void> delete(String conversationId) async {
    try {
      LoggerService.debug(
        'DifyChatRepository: Deletando conversa: $conversationId',
        name: 'DifyChatRepository',
      );

      // No Dify, não há endpoint para deletar conversas
      // Remove apenas do cache local
      await _removeConversationFromCache(conversationId);
      await _removeMessagesFromCache(conversationId);

      LoggerService.debug(
        'Conversa removida do cache: $conversationId',
        name: 'DifyChatRepository',
      );
    } catch (error) {
      LoggerService.error(
        'Erro ao deletar conversa: $error',
        name: 'DifyChatRepository',
      );
      throw DomainError.unexpected;
    }
  }

  // SYNC CONVERSATIONS (busca do Dify)
  @override
  Future<List<ConversationEntity>> sync({bool forceRefresh = false}) async {
    try {
      LoggerService.debug(
        'DifyChatRepository: Sincronizando com Dify (forceRefresh: $forceRefresh)',
        name: 'DifyChatRepository',
      );

      if (!forceRefresh && !await _shouldSync()) {
        final cachedConversations = await _loadConversationsFromCache();
        LoggerService.debug(
          'Sync não necessário, retornando cache: ${cachedConversations.length} conversas',
          name: 'DifyChatRepository',
        );
        return cachedConversations.map((model) => model.toEntity()).toList();
      }

      // Busca usuário atual
      final currentUser = await _loadCurrentUser.load();
      if (currentUser == null) {
        throw DomainError.accessDenied;
      }

      // Busca conversas do Dify
      final difyResponse = await difyApiClient.getConversations(
        userId: currentUser.id,
        limit: 50, // Busca mais conversas para cache
      );

      // Converte para models do app
      final conversations = DifyConversationAdapter.fromDifyList(
        difyConversations: difyResponse.data,
        userId: currentUser.id,
      );

      // Salva no cache
      await _saveConversationsToCache(conversations);

      // Atualiza timestamp do último sync
      await localStorage.save(
        key: _lastSyncKey,
        value: DateTime.now().toIso8601String(),
      );

      LoggerService.debug(
        'Sync concluído: ${conversations.length} conversas sincronizadas',
        name: 'DifyChatRepository',
      );

      return conversations.map((model) => model.toEntity()).toList();
    } catch (error) {
      LoggerService.error(
        'Erro no sync: $error',
        name: 'DifyChatRepository',
      );

      // Fallback para cache se sync falhar
      final cachedConversations = await _loadConversationsFromCache();
      if (cachedConversations.isNotEmpty) {
        LoggerService.debug(
          'Sync falhou, retornando cache: ${cachedConversations.length} conversas',
          name: 'DifyChatRepository',
        );
        return cachedConversations.map((model) => model.toEntity()).toList();
      }
      throw DomainError.networkError;
    }
  }

  // LOAD MESSAGES para uma conversa específica
  Future<List<MessageEntity>> loadMessages({
    required String conversationId,
    int limit = 30,
    String? startAfter,
  }) async {
    try {
      LoggerService.debug(
        'DifyChatRepository: Carregando mensagens para conversa: $conversationId',
        name: 'DifyChatRepository',
      );

      // 1. TENTA CARREGAR DO CACHE PRIMEIRO
      final cachedMessages = await _loadMessagesFromCache(conversationId);
      if (cachedMessages.isNotEmpty) {
        LoggerService.debug(
          'Mensagens carregadas do CACHE: ${cachedMessages.length}',
          name: 'DifyChatRepository',
        );
        return cachedMessages
            .map((model) => model.toEntity())
            .take(limit)
            .toList();
      }

      // 2. SÓ SE CACHE VAZIO, busca do Dify API
      LoggerService.debug(
        'Cache vazio, buscando do Dify API...',
        name: 'DifyChatRepository',
      );

      final currentUser = await _loadCurrentUser.load();
      if (currentUser == null) {
        throw DomainError.accessDenied;
      }

      final difyResponse = await difyApiClient.getMessages(
        userId: currentUser.id,
        conversationId: conversationId,
        limit: limit,
        firstId: startAfter,
      );

      // Converte para models do app
      final messages = DifyMessageAdapter.fromDifyList(
        difyMessages: difyResponse.data,
      );

      // Salva no cache para próximas vezes
      await _saveMessagesToCache(conversationId, messages);

      LoggerService.debug(
        'Mensagens carregadas do DIFY API: ${messages.length}',
        name: 'DifyChatRepository',
      );

      return messages.map((model) => model.toEntity()).toList();
    } catch (error) {
      LoggerService.error(
        'Erro ao carregar mensagens: $error',
        name: 'DifyChatRepository',
      );
      throw DomainError.networkError;
    }
  }

  // MÉTODOS PRIVADOS (Cache Management)

  Future<List<ConversationModel>> _loadConversationsFromCache() async {
    try {
      final cacheString = await localStorage.fetch(_conversationsKey);
      if (cacheString == null || cacheString.isEmpty) {
        return [];
      }
      return ConversationModel.fromCacheString(cacheString);
    } catch (_) {
      return [];
    }
  }

  Future<List<MessageModel>> _loadMessagesFromCache(
      String conversationId) async {
    try {
      final cacheString =
          await localStorage.fetch('$_messagesPrefix$conversationId');
      if (cacheString == null || cacheString.isEmpty) {
        return [];
      }
      return MessageModel.fromCacheString(cacheString);
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveConversationsToCache(
      List<ConversationModel> conversations) async {
    await localStorage.save(
      key: _conversationsKey,
      value: ConversationModel.listToCacheString(conversations),
    );
  }

  Future<void> _saveMessagesToCache(
      String conversationId, List<MessageModel> messages) async {
    await localStorage.save(
      key: '$_messagesPrefix$conversationId',
      value: MessageModel.listToCacheString(messages),
    );
  }

  Future<void> _addConversationToCache(ConversationModel conversation) async {
    final cached = await _loadConversationsFromCache();
    cached.insert(0, conversation); // Adiciona no início
    await _saveConversationsToCache(cached);
  }

  Future<void> _addMessageToCache(
      String conversationId, MessageModel message) async {
    final cached = await _loadMessagesFromCache(conversationId);
    cached.add(message);
    await localStorage.save(
      key: '$_messagesPrefix$conversationId',
      value: MessageModel.listToCacheString(cached),
    );
  }

  Future<void> _updateConversationInCache(
      ConversationModel conversation) async {
    final cached = await _loadConversationsFromCache();
    final index = cached.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      cached[index] = conversation;
      await _saveConversationsToCache(cached);
    }
  }

  Future<void> _removeConversationFromCache(String conversationId) async {
    final cached = await _loadConversationsFromCache();
    cached.removeWhere((c) => c.id == conversationId);
    await _saveConversationsToCache(cached);
  }

  Future<void> _removeMessagesFromCache(String conversationId) async {
    await localStorage.delete('$_messagesPrefix$conversationId');
  }

  Future<bool> _shouldSync() async {
    try {
      // Verifica se passou do tempo limite (30 minutos)
      final lastSyncString = await localStorage.fetch(_lastSyncKey);
      if (lastSyncString == null) return true;

      final lastSync = DateTime.parse(lastSyncString);
      final timeDifference = DateTime.now().difference(lastSync);

      // Se passou mais de 30 minutos, precisa sincronizar
      return timeDifference.inMinutes >= 30;
    } catch (_) {
      return true;
    }
  }

  // MÉTODOS PÚBLICOS para uso no Presenter e SyncService

  /// Adiciona mensagem ao cache (público para uso no presenter)
  Future<void> addMessageToCache(
      String conversationId, MessageEntity message) async {
    final messageModel = MessageModel.fromEntity(message);
    await _addMessageToCache(conversationId, messageModel);
  }

  /// Adiciona múltiplas mensagens ao cache
  Future<void> addMessagesToCache(
      String conversationId, List<MessageEntity> messages) async {
    final messageModels =
        messages.map((msg) => MessageModel.fromEntity(msg)).toList();
    await _saveMessagesToCache(conversationId, messageModels);
  }

  /// Atualiza conversa no cache (público para uso no presenter)
  Future<void> updateConversationInCache(
      ConversationEntity conversation) async {
    final conversationModel = ConversationModel.fromEntity(conversation);
    await _updateConversationInCache(conversationModel);
  }

  /// Salva lista de conversas no cache (público para SyncService)
  Future<void> saveConversationsToCache(
      List<ConversationModel> conversations) async {
    await _saveConversationsToCache(conversations);
  }

  /// Salva mensagens de uma conversa no cache (público para SyncService)
  Future<void> saveMessagesToCache(
      String conversationId, List<MessageModel> messages) async {
    await _saveMessagesToCache(conversationId, messages);
  }

  /// Carrega conversas do cache (público para SyncService)
  Future<List<ConversationModel>> loadConversationsFromCache() async {
    return await _loadConversationsFromCache();
  }

  /// Carrega mensagens de uma conversa do cache (público para SyncService)
  Future<List<MessageModel>> loadMessagesFromCache(
      String conversationId) async {
    return await _loadMessagesFromCache(conversationId);
  }

  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 30,
    String? startAfter,
  }) async {
    return loadMessages(
      conversationId: conversationId,
      limit: limit,
      startAfter: startAfter,
    );
  }

  // Limpa cache (para logout)
  Future<void> clearCache() async {
    try {
      LoggerService.debug(
        'DifyChatRepository: Limpando cache',
        name: 'DifyChatRepository',
      );

      await localStorage.delete(_conversationsKey);
      await localStorage.delete(_lastSyncKey);

      // Remove todos os caches de mensagens (mais complexo, mas funcional)
      // Nota: idealmente teríamos uma lista de conversationIds para limpar
      LoggerService.debug(
        'Cache do DifyChatRepository limpo',
        name: 'DifyChatRepository',
      );
    } catch (error) {
      LoggerService.error(
        'Erro ao limpar cache: $error',
        name: 'DifyChatRepository',
      );
    }
  }

  /// Helper para truncar mensagem para preview
  String _truncateMessage(String message) {
    if (message.length <= 100) return message;
    return '${message.substring(0, 97)}...';
  }

  /// Atualiza contador de mensagens de uma conversa
  Future<void> updateMessageCount(String conversationId, int newCount) async {
    try {
      final cached = await _loadConversationsFromCache();
      final index = cached.indexWhere((c) => c.id == conversationId);

      if (index != -1) {
        final updated = ConversationModel(
          id: cached[index].id,
          userId: cached[index].userId,
          title: cached[index].title,
          createdAt: cached[index].createdAt,
          updatedAt: DateTime.now(), // Atualiza timestamp
          messageCount: newCount,
          isActive: cached[index].isActive,
          lastMessage: cached[index].lastMessage,
          messages: cached[index].messages,
        );

        cached[index] = updated;
        await _saveConversationsToCache(cached);

        LoggerService.debug(
          'Contador de mensagens atualizado: $conversationId → $newCount',
          name: 'DifyChatRepository',
        );
      }
    } catch (error) {
      LoggerService.error(
        'Erro ao atualizar contador de mensagens: $error',
        name: 'DifyChatRepository',
      );
    }
  }

  /// Atualiza última mensagem de uma conversa (para preview no drawer)
  Future<void> updateLastMessage(
      String conversationId, String lastMessage) async {
    try {
      final cached = await _loadConversationsFromCache();
      final index = cached.indexWhere((c) => c.id == conversationId);

      if (index != -1) {
        final updated = ConversationModel(
          id: cached[index].id,
          userId: cached[index].userId,
          title: cached[index].title,
          createdAt: cached[index].createdAt,
          updatedAt: DateTime.now(), // Atualiza timestamp
          messageCount: cached[index].messageCount,
          isActive: cached[index].isActive,
          lastMessage: _truncateMessage(lastMessage),
          messages: cached[index].messages,
        );

        cached[index] = updated;
        await _saveConversationsToCache(cached);

        LoggerService.debug(
          'Última mensagem atualizada: $conversationId',
          name: 'DifyChatRepository',
        );
      }
    } catch (error) {
      LoggerService.error(
        'Erro ao atualizar última mensagem: $error',
        name: 'DifyChatRepository',
      );
    }
  }
}
