import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat/chat.dart';
import '../../domain/helpers/helpers.dart';
import '../../domain/usecases/chat/chat.dart';
import '../../domain/usecases/usecases.dart';
import '../../infra/cache/cache.dart';
import '../../main/services/logger_service.dart';
import '../models/chat/chat.dart';
import './messages_repository.dart';

class ChatRepository
    implements
        LoadConversations,
        CreateConversation,
        SendMessage,
        UpdateConversation,
        DeleteConversation,
        SyncConversations {
  final FirebaseFirestore firestore;
  final SharedPreferencesStorageAdapter localStorage;
  final MessagesRepository messagesRepository;
  final LoadCurrentUser _loadCurrentUser;

  static const String _conversationsKey = 'conversations_cache';
  static const String _lastSyncKey = 'conversations_last_sync';
  static const String _messagesPrefix = 'messages_cache_';

  ChatRepository({
    required this.firestore,
    required this.localStorage,
    required this.messagesRepository,
    required LoadCurrentUser loadCurrentUser,
  }) : _loadCurrentUser = loadCurrentUser;

  // LOAD CONVERSATIONS (implementa LoadConversations)
  @override
  Future<List<ConversationEntity>> load({
    int limit = 20,
    String? startAfter,
  }) async {
    try {
      // Tenta carregar do cache primeiro
      final cachedConversations = await _loadConversationsFromCache();
      if (cachedConversations.isNotEmpty) {
        return cachedConversations
            .map((model) => model.toEntity())
            .take(limit)
            .toList();
      }

      // Se não há cache, busca do Firestore
      return await sync();
    } catch (error) {
      throw DomainError.unexpected;
    }
  }

  // CREATE CONVERSATION
  @override
  Future<ConversationEntity> create({
    required String userId,
    required String firstMessage,
  }) async {
    try {
      final conversationModel = ConversationModel.createNew(
        userId: userId,
        firstMessage: firstMessage,
      );

      // Salva no Firestore
      await firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .doc(conversationModel.id)
          .set(conversationModel.toFirestore());

      // Atualiza cache local
      await _addConversationToCache(conversationModel);

      return conversationModel.toEntity();
    } catch (error) {
      throw DomainError.unexpected;
    }
  }

  // SEND MESSAGE (local + Firestore)
  @override
  Future<MessageEntity> send({
    required String conversationId,
    required String content,
    required MessageType type,
    Map<String, dynamic>? metadata,
  }) async {
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
    try {
      // Salva no cache local imediatamente (UX)
      await messagesRepository.addMessageToCache(conversationId, messageModel);

      // Salva no Firestore em background
      _saveMessageToFirestore(messageModel);

      return messageModel.toEntity();
    } catch (error) {
      // Se falhar, marca como "failed"
      final failedMessage = messageModel.copyWith(status: MessageStatus.failed);
      await messagesRepository.updateMessageInCache(
          conversationId, failedMessage);
      await _updateMessageStatusInFirestore(failedMessage);

      throw DomainError.unexpected;
    }
  }

  // UPDATE CONVERSATION
  @override
  Future<ConversationEntity> update(ConversationEntity conversation) async {
    try {
      final model = ConversationModel.fromEntity(conversation);

      // Atualiza no Firestore
      await firestore
          .collection('users')
          .doc(conversation.userId)
          .collection('conversations')
          .doc(conversation.id)
          .update(model.toFirestore());

      // Atualiza cache local
      await _updateConversationInCache(model);

      return conversation;
    } catch (error) {
      throw DomainError.unexpected;
    }
  }

  // DELETE CONVERSATION
  @override
  Future<void> delete(String conversationId) async {
    try {
      final currentUser = await _loadCurrentUser.load();
      if (currentUser == null) {
        throw DomainError.accessDenied;
      }

      final conversationRef = firestore
          .collection('users')
          .doc(currentUser.id)
          .collection('conversations')
          .doc(conversationId);

      // Delete subcollection messages first
      final messagesQuery = conversationRef.collection('messages');
      final messagesSnapshot = await messagesQuery.get();

      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete conversation document
      await conversationRef.delete();

      // Remove from cache
      await _removeConversationFromCache(conversationId);

      LoggerService.info('Conversa deletada: $conversationId',
          name: 'ChatRepository');
    } catch (error) {
      LoggerService.error('Erro ao deletar conversa: $error',
          name: 'ChatRepository');
      throw DomainError.unexpected;
    }
  }

  // SYNC CONVERSATIONS
  @override
  Future<List<ConversationEntity>> sync({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && !await _shouldSync()) {
        final cachedConversations = await _loadConversationsFromCache();
        return cachedConversations.map((model) => model.toEntity()).toList();
      }

      // Busca do Firestore
      final conversations = await _fetchConversationsFromFirestore();

      // Salva no cache
      await _saveConversationsToCache(conversations);

      // Atualiza timestamp do último sync
      await localStorage.save(
        key: _lastSyncKey,
        value: DateTime.now().toIso8601String(),
      );

      return conversations.map((model) => model.toEntity()).toList();
    } catch (error) {
      final cachedConversations = await _loadConversationsFromCache();
      if (cachedConversations.isNotEmpty) {
        return cachedConversations.map((model) => model.toEntity()).toList();
      }
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

  Future<void> _saveConversationsToCache(
      List<ConversationModel> conversations) async {
    await localStorage.save(
      key: _conversationsKey,
      value: ConversationModel.listToCacheString(conversations),
    );
  }

  Future<void> _addConversationToCache(ConversationModel conversation) async {
    final cached = await _loadConversationsFromCache();
    cached.insert(0, conversation); // Adiciona no início
    await _saveConversationsToCache(cached);
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

  // MÉTODOS FIRESTORE

  Future<List<ConversationModel>> _fetchConversationsFromFirestore({
    int limit = 20,
    String? startAfter,
  }) async {
    try {
      // Busca o usuário atual
      final currentUser = await _loadCurrentUser.load();
      if (currentUser == null) {
        throw DomainError.accessDenied;
      }

      Query query = firestore
          .collection('users')
          .doc(currentUser.id)
          .collection('conversations')
          .orderBy('updatedAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfter([startAfter]);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => ConversationModel.fromFirestore({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (error) {
      LoggerService.error('Erro ao buscar conversas: $error',
          name: 'ChatRepository');
      throw DomainError.networkError;
    }
  }

  // Método síncrono para salvar no Firestore
  Future<void> _saveMessageToFirestore(MessageModel message) async {
    try {
      // Busca conversa para pegar userId
      final conversations = await _loadConversationsFromCache();
      final conversation = conversations.firstWhere(
        (c) => c.id == message.conversationId,
        orElse: () => throw Exception('Conversation not found'),
      );

      // Salva mensagem no Firestore
      await firestore
          .collection('users')
          .doc(conversation.userId)
          .collection('conversations')
          .doc(message.conversationId)
          .collection('messages')
          .doc(message.id)
          .set(message.toFirestore());

      // Atualiza status para sent
      final sentMessage = message.copyWith(status: MessageStatus.sent);

      // Atualiza status da mensagem no cache
      await messagesRepository.updateMessageInCache(
          message.conversationId, sentMessage);

      LoggerService.debug('Mensagem ${message.id} salva com status: sent',
          name: 'ChatRepository');
    } catch (error) {
      LoggerService.error('Erro ao salvar mensagem: $error',
          name: 'ChatRepository');

      // Marca como falha
      final failedMessage = message.copyWith(status: MessageStatus.failed);
      await messagesRepository.updateMessageInCache(
          message.conversationId, failedMessage);
      await _updateMessageStatusInFirestore(failedMessage);

      rethrow;
    }
  }

  // Atualizar apenas status no Firestore
  Future<void> _updateMessageStatusInFirestore(MessageModel message) async {
    try {
      final conversations = await _loadConversationsFromCache();
      final conversation = conversations.firstWhere(
        (c) => c.id == message.conversationId,
        orElse: () => throw Exception('Conversation not found'),
      );

      await firestore
          .collection('users')
          .doc(conversation.userId)
          .collection('conversations')
          .doc(message.conversationId)
          .collection('messages')
          .doc(message.id)
          .update({
        'status': message.status.name,
        'timestamp': message.timestamp,
      });

      LoggerService.debug(
          'Status da mensagem ${message.id} atualizado para: ${message.status.name}',
          name: 'ChatRepository');
    } catch (error) {
      LoggerService.error('Erro ao atualizar status da mensagem: $error',
          name: 'ChatRepository');
      // Não relançar erro pra não quebrar o fruxo
    }
  }

  // Tentar reenviar mensagens com falha
  Future<void> retryFailedMessage(
      String messageId, String conversationId) async {
    try {
      // Busca mensagem do cache
      final cachedMessages =
          await messagesRepository.loadMessagesFromCache(conversationId);
      final failedMessage = cachedMessages.firstWhere(
        (m) => m.id == messageId && m.status == MessageStatus.failed,
        orElse: () => throw Exception('Failed message not found'),
      );

      // Marca como enviando novamente
      final retryMessage = failedMessage.copyWith(
        status: MessageStatus.sending,
        timestamp: DateTime.now(), // Novo timestamp
      );

      await messagesRepository.updateMessageInCache(
          conversationId, retryMessage);

      // Tenta salvar novamente
      await _saveMessageToFirestore(retryMessage);
    } catch (error) {
      LoggerService.error('Erro ao tentar reenviar mensagem: $error',
          name: 'ChatRepository');
      throw DomainError.unexpected;
    }
  }

  Future<bool> _shouldSync() async {
    try {
      // Verifica se passou do tempo limite (1 hora para conversas)
      final lastSyncString = await localStorage.fetch(_lastSyncKey);
      if (lastSyncString == null) return true;

      final lastSync = DateTime.parse(lastSyncString);
      final timeDifference = DateTime.now().difference(lastSync);

      // Se passou mais de 1 hora, precisa sincronizar
      return timeDifference.inHours >= 1;
    } catch (_) {
      return true;
    }
  }

  Future<void> _removeConversationFromCache(String conversationId) async {
    final cached = await _loadConversationsFromCache();
    cached.removeWhere((c) => c.id == conversationId);
    await _saveConversationsToCache(cached);

    // Remove messages cache também
    await localStorage.delete('$_messagesPrefix$conversationId');
  }
}
