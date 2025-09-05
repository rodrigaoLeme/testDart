import 'dart:async';

import '../../domain/helpers/helpers.dart';
import '../../domain/usecases/user/load_current_user.dart';
import '../../main/services/logger_service.dart';
import '../adapters/dify_conversation_adapter.dart';
import '../adapters/dify_message_adapter.dart';
import '../clients/dify_api_client.dart';
import '../models/chat/chat.dart';
import '../models/dify/dify.dart';
import '../repositories/dify_chat_repository.dart';
import 'dify_service.dart';

// Service responsável por sincronizar completamente os dados do Dify no splash
class DifySyncService {
  final DifyApiClient difyApiClient;
  final DifyChatRepository difyChatRepository;
  final LoadCurrentUser loadCurrentUser;

  DifySyncService({
    required this.difyApiClient,
    required this.difyChatRepository,
    required this.loadCurrentUser,
  });

  // Sincronização completa: limpa cache + carrega tudo do Dify
  Future<DifySyncResult> fullSync({
    int conversationsLimit = 100,
    int messagesPerConversation = 100,
    Function(String)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      LoggerService.debug(
        'DifySyncService: Iniciando sincronização completa',
        name: 'DifySyncService',
      );

      onProgress?.call('Verificando usuário...');

      // 1. Verificar usuário atual
      final currentUser = await loadCurrentUser.load();
      if (currentUser == null) {
        LoggerService.error('Usuário não encontrado para sync',
            name: 'DifySyncService');
        throw DomainError.accessDenied;
      }

      LoggerService.debug('Sync para usuário: ${currentUser.id}',
          name: 'DifySyncService');

      onProgress?.call('Limpando cache local...');

      // 2. Limpar todo o cache local
      await difyChatRepository.clearCache();
      LoggerService.debug('Cache local limpo', name: 'DifySyncService');

      onProgress?.call('Carregando conversas do Dify...');

      // 3. Carregar conversas do Dify
      final conversationsResponse = await difyApiClient.getConversations(
        userId: currentUser.id,
        limit: conversationsLimit,
      );

      LoggerService.debug(
        'Conversas carregadas do Dify: ${conversationsResponse.data.length}',
        name: 'DifySyncService',
      );

      if (conversationsResponse.data.isEmpty) {
        LoggerService.debug('Nenhuma conversa encontrada no Dify',
            name: 'DifySyncService');

        stopwatch.stop();
        return DifySyncResult(
          success: true,
          conversationsCount: 0,
          messagesCount: 0,
          duration: stopwatch.elapsed,
          message: 'Nenhuma conversa encontrada',
        );
      }

      // 4. Converter conversas para models do app
      final conversations = DifyConversationAdapter.fromDifyList(
        difyConversations: conversationsResponse.data,
        userId: currentUser.id,
      );

      // 5. Salvar conversas no cache
      await difyChatRepository.saveConversationsToCache(conversations);
      LoggerService.debug('Conversas salvas no cache local',
          name: 'DifySyncService');

      // 6. Popular o cache do DifyService para mapeamento de IDs
      _populateDifyServiceCache(conversationsResponse.data);

      // 7. Para cada conversa, carregar mensagens
      int totalMessages = 0;

      for (int i = 0; i < conversationsResponse.data.length; i++) {
        final difyConversation = conversationsResponse.data[i];
        final progress =
            ((i + 1) / conversationsResponse.data.length * 100).round();

        onProgress?.call('Carregando mensagens... ($progress%)');

        try {
          LoggerService.debug(
            'Carregando mensagens da conversa: ${difyConversation.id}',
            name: 'DifySyncService',
          );

          // Carregar mensagens desta conversa
          final messagesResponse = await difyApiClient.getMessages(
            userId: currentUser.id,
            conversationId: difyConversation.id,
            limit: messagesPerConversation,
          );

          if (messagesResponse.data.isNotEmpty) {
            // Converter mensagens para models do app
            final messages = DifyMessageAdapter.fromDifyList(
              difyMessages: messagesResponse.data,
            );

            // Salvar mensagens no cache
            await difyChatRepository.saveMessagesToCache(
                difyConversation.id, messages);

            totalMessages += messages.length;

            LoggerService.debug(
              'Mensagens salvas: ${difyConversation.id} → ${messages.length} msgs',
              name: 'DifySyncService',
            );
          }

          // Pequeno delay para não sobrecarregar a API
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (error) {
          LoggerService.error(
            'Erro ao carregar mensagens da conversa ${difyConversation.id}: $error',
            name: 'DifySyncService',
          );
          // Continua com próxima conversa
        }
      }

      stopwatch.stop();

      LoggerService.debug(
        'Sincronização completa finalizada: ${conversations.length} conversas, $totalMessages mensagens em ${stopwatch.elapsed.inSeconds}s',
        name: 'DifySyncService',
      );

      return DifySyncResult(
        success: true,
        conversationsCount: conversations.length,
        messagesCount: totalMessages,
        duration: stopwatch.elapsed,
        message: 'Sincronização completa realizada com sucesso',
      );
    } catch (error) {
      stopwatch.stop();

      LoggerService.error(
        'Erro na sincronização completa: $error',
        name: 'DifySyncService',
      );

      return DifySyncResult(
        success: false,
        conversationsCount: 0,
        messagesCount: 0,
        duration: stopwatch.elapsed,
        message: 'Erro na sincronização: $error',
        error: error,
      );
    }
  }

  // Sincronização incremental (apenas conversas novas/atualizadas)
  Future<DifySyncResult> incrementalSync({
    int limit = 20,
    Function(String)? onProgress,
  }) async {
    try {
      LoggerService.debug(
        'DifySyncService: Iniciando sincronização incremental',
        name: 'DifySyncService',
      );

      onProgress?.call('Verificando atualizações...');

      final currentUser = await loadCurrentUser.load();
      if (currentUser == null) {
        throw DomainError.accessDenied;
      }

      // Carrega apenas conversas mais recentes
      final conversationsResponse = await difyApiClient.getConversations(
        userId: currentUser.id,
        limit: limit,
        sortBy: '-updated_at', // Mais recentes primeiro
      );

      if (conversationsResponse.data.isEmpty) {
        return DifySyncResult(
          success: true,
          conversationsCount: 0,
          messagesCount: 0,
          duration: Duration.zero,
          message: 'Nenhuma atualização necessária',
        );
      }

      // Converte e salva no cache (merge com existentes)
      final conversations = DifyConversationAdapter.fromDifyList(
        difyConversations: conversationsResponse.data,
        userId: currentUser.id,
      );

      // Carrega conversas existentes e faz merge
      final existingConversations =
          await difyChatRepository.loadConversationsFromCache();
      final mergedConversations =
          _mergeConversations(existingConversations, conversations);

      await difyChatRepository.saveConversationsToCache(mergedConversations);

      LoggerService.debug(
        'Sincronização incremental concluída: ${conversations.length} conversas processadas',
        name: 'DifySyncService',
      );

      return DifySyncResult(
        success: true,
        conversationsCount: conversations.length,
        messagesCount: 0,
        duration: Duration.zero,
        message: 'Sincronização incremental realizada',
      );
    } catch (error) {
      LoggerService.error(
        'Erro na sincronização incremental: $error',
        name: 'DifySyncService',
      );

      return DifySyncResult(
        success: false,
        conversationsCount: 0,
        messagesCount: 0,
        duration: Duration.zero,
        message: 'Erro na sincronização incremental: $error',
        error: error,
      );
    }
  }

  // Testa conexão com o Dify
  Future<bool> testConnection() async {
    try {
      LoggerService.debug('Testando conexão com Dify...',
          name: 'DifySyncService');
      return await difyApiClient.testConnection();
    } catch (error) {
      LoggerService.error('Erro no teste de conexão: $error',
          name: 'DifySyncService');
      return false;
    }
  }

  // Popula o cache do DifyService
  void _populateDifyServiceCache(
      List<DifyConversationModel> difyConversations) {
    try {
      LoggerService.debug(
        'Populando cache do DifyService com ${difyConversations.length} conversas',
        name: 'DifySyncService',
      );

      for (final difyConv in difyConversations) {
        // Mapeia ID local → ID do Dify para manter contexto
        DifyService.setConversationMapping(difyConv.id, difyConv.id);

        LoggerService.debug(
          'Mapeamento criado: ${difyConv.id} → ${difyConv.id}',
          name: 'DifySyncService',
        );
      }

      LoggerService.debug(
        'Cache do DifyService populado com ${difyConversations.length} mapeamentos',
        name: 'DifySyncService',
      );
    } catch (error) {
      LoggerService.error(
        'Erro ao popular cache do DifyService: $error',
        name: 'DifySyncService',
      );
    }
  }

  // Merge inteligente de conversas (prioriza mais recentes)
  List<ConversationModel> _mergeConversations(
    List<ConversationModel> existing,
    List<ConversationModel> newConversations,
  ) {
    final merged = <String, ConversationModel>{};

    // Adiciona existentes
    for (final conversation in existing) {
      merged[conversation.id] = conversation;
    }

    // Sobrescreve com novas (mais recentes)
    for (final conversation in newConversations) {
      merged[conversation.id] = conversation;
    }

    // Retorna lista ordenada por updatedAt
    final result = merged.values.toList();
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return result;
  }
}

// Resultado da sincronização
class DifySyncResult {
  final bool success;
  final int conversationsCount;
  final int messagesCount;
  final Duration duration;
  final String message;
  final dynamic error;

  DifySyncResult({
    required this.success,
    required this.conversationsCount,
    required this.messagesCount,
    required this.duration,
    required this.message,
    this.error,
  });

  @override
  String toString() {
    return 'DifySyncResult(success: $success, conversations: $conversationsCount, messages: $messagesCount, duration: ${duration.inSeconds}s)';
  }
}
