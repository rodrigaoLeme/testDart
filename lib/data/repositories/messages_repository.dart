import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat/chat.dart';
import '../../domain/helpers/helpers.dart';
import '../../domain/usecases/chat/load_messages.dart';
import '../../infra/cache/cache.dart';
import '../../main/services/logger_service.dart';
import '../models/chat/chat.dart';

class MessagesRepository implements LoadMessages {
  final FirebaseFirestore firestore;
  final SharedPreferencesStorageAdapter localStorage;

  static const String _messagesPrefix = 'messages_cache_';

  MessagesRepository({
    required this.firestore,
    required this.localStorage,
  });

  // LOAD MESSAGES para uma conversa específica
  @override
  Future<List<MessageEntity>> load({
    required String conversationId,
    int limit = 30,
    String? startAfter,
  }) async {
    try {
      // Tenta carregar do cache primeiro
      final cachedMessages = await loadMessagesFromCache(conversationId);
      if (cachedMessages.isNotEmpty) {
        return cachedMessages
            .map((model) => model.toEntity())
            .take(limit)
            .toList();
      }

      // Se não há cache, busca do Firestore
      return await _fetchMessagesFromFirestore(
        conversationId: conversationId,
        limit: limit,
        startAfter: startAfter,
      );
    } catch (error) {
      throw DomainError.unexpected;
    }
  }

  Future<List<MessageModel>> loadMessagesFromCache(
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

  // MÉTODOS PRIVADOS

  Future<List<MessageEntity>> _fetchMessagesFromFirestore({
    required String conversationId,
    int limit = 30,
    String? startAfter,
  }) async {
    try {
      // Para buscar mensagens, precisamos do userId - pode vir de cache da conversa
      // ou buscar diretamente da estrutura do Firestore

      // Método simples: buscar de todos os usuários (menos eficiente, mas funciona)
      // Método otimizado: manter userId no cache ou estrutura da mensagem

      Query query = firestore
          .collectionGroup(
              'messages') // Busca em todas as subcollections de messages
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('timestamp', descending: false)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfter([startAfter]);
      }

      final querySnapshot = await query.get();

      final messages = querySnapshot.docs
          .map((doc) => MessageModel.fromFirestore({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();

      // Salva no cache
      await _saveMessagesToCache(conversationId, messages);

      return messages.map((model) => model.toEntity()).toList();
    } catch (error) {
      LoggerService.error('Erro ao buscar mensagens: $error',
          name: 'MessagesRepository');
      throw DomainError.networkError;
    }
  }

  // MÉTODOS AUXILIARES (para outros repositories usarem)

  Future<void> addMessageToCache(
      String conversationId, MessageModel message) async {
    final cached = await loadMessagesFromCache(conversationId);
    cached.add(message);
    await localStorage.save(
      key: '$_messagesPrefix$conversationId',
      value: MessageModel.listToCacheString(cached),
    );
  }

  Future<void> updateMessageInCache(
      String conversationId, MessageModel message) async {
    final cached = await loadMessagesFromCache(conversationId);
    final index = cached.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      cached[index] = message;
      await localStorage.save(
        key: '$_messagesPrefix$conversationId',
        value: MessageModel.listToCacheString(cached),
      );
    }
  }

  Future<void> _saveMessagesToCache(
      String conversationId, List<MessageModel> messages) async {
    await localStorage.save(
      key: '$_messagesPrefix$conversationId',
      value: MessageModel.listToCacheString(messages),
    );
  }
}
