import 'dart:async';
import 'dart:convert';

import 'package:seven_chat_app/main/services/logger_service.dart';

import '../../domain/helpers/helpers.dart';
import '../../domain/usecases/chat/send_to_dify.dart';
import '../http/http.dart';
import '../models/dify/dify.dart';

class DifyService implements SendToDify {
  final HttpClient httpClient;
  final String apiKey;
  final String baseUrl;

  // Cache para manter conversation_id do Dify
  static final Map<String, String> _conversationCache = {};

  DifyService({
    required this.httpClient,
    required this.apiKey,
    required this.baseUrl,
  });

  @override
  Stream<DifyStreamResponse> sendMessage({
    required String message,
    required String conversationId,
    String? userId,
  }) async* {
    try {
      LoggerService.debug(
        'Dify: Recebido - conversationId: "$conversationId", userId: "$userId", message: "${message.substring(0, 10)}"',
        name: 'DifyService',
      );

      LoggerService.debug('Dify: Enviando mensagem...', name: 'DifyService');

      // Busca o conversation_id do Dify se já existe
      final difyConversationId = _getDifyConversationId(conversationId);

      LoggerService.debug(
        'Cache check - Local ID: "$conversationId" → Dify ID: "${difyConversationId.isEmpty ? "NOVA CONVERSA" : difyConversationId}"',
        name: 'DifyService',
      );

      final request = DifyRequestModel(
        query: message,
        user: userId ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: difyConversationId,
        responseMode: true,
      );

      LoggerService.debug(
        'Request para Dify: ${json.encode(request.toJson())}',
        name: 'DifyService',
      );

      final response = await httpClient.request(
        url: '$baseUrl/chat-messages',
        method: HttpMethod.post,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: request.toJson(),
      );

      if (response is String) {
        yield* _handleStreamingWithLocalSimulation(response, conversationId);
      }
    } catch (error, stackTrace) {
      LoggerService.error(
        'Erro no Dify Service: $error',
        name: 'DifyService',
        error: error,
        stackTrace: stackTrace,
      );

      if (error.toString().contains('network') ||
          error.toString().contains('timeout')) {
        throw DomainError.networkError;
      } else {
        throw DomainError.unexpected;
      }
    }
  }

  // Determina qual conversation_id enviar para o Dify
  String _getDifyConversationId(String localConversationId) {
    // 1. Se já está no cache, use o ID do Dify
    if (_conversationCache.containsKey(localConversationId)) {
      final difyId = _conversationCache[localConversationId]!;
      LoggerService.debug(
        'Usando conversation_id do cache: $difyId',
        name: 'DifyService',
      );
      return difyId;
    }

    // 2. Se o localConversationId já parece ser um ID do Dify, use ele
    if (localConversationId.length > 20 &&
        !localConversationId.startsWith('temp_')) {
      LoggerService.debug(
        'ID parece ser do Dify, usando diretamente: $localConversationId',
        name: 'DifyService',
      );
      return localConversationId;
    }

    // 3. Nova conversa - enviar string vazia
    LoggerService.debug(
      'Nova conversa, enviando conversation_id vazio',
      name: 'DifyService',
    );
    return '';
  }

  // Atualiza o mapeamento no cache quando o conversationId muda
  static void updateConversationCache(String oldLocalId, String newDifyId) {
    // Se existia mapeamento com o ID antigo
    if (_conversationCache.containsKey(oldLocalId)) {
      final difyConversationId = _conversationCache[oldLocalId];

      // Remove o mapeamento antigo
      _conversationCache.remove(oldLocalId);

      // Adiciona o novo mapeamento correto
      _conversationCache[newDifyId] = difyConversationId!;

      LoggerService.debug(
        'Cache do Dify atualizado: $oldLocalId -> $newDifyId (DifyId: $difyConversationId)',
        name: 'DifyService',
      );
    }
  }

  Stream<DifyStreamResponse> _handleStreamingWithLocalSimulation(
      String sseData, String localConversationId) async* {
    String fullAnswer = '';
    String? difyConversationId;
    String? difyMessageId;

    try {
      // PROCESSA Todo O STREAMING PARA PEGAR RESPOSTA COMPLETA
      final lines = sseData.split('\n');

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final jsonString = line.substring(6).trim();
          if (jsonString.isEmpty || jsonString == '[DONE]') continue;

          try {
            final json = jsonDecode(jsonString);
            final event = json['event'] as String?;
            final answer = json['answer'] as String?;

            // Acumula resposta
            if (event == 'agent_message' && answer != null) {
              fullAnswer += answer;
            }

            // Salva metadados
            if (json['conversation_id'] != null) {
              var conversationId = json['conversation_id'];
              if (conversationId != null && conversationId.isNotEmpty) {
                difyConversationId = conversationId;
                _conversationCache[localConversationId] = conversationId;

                if (!localConversationId.startsWith('temp_')) {
                  _conversationCache[conversationId] = conversationId;
                }

                LoggerService.debug(
                  'Cache atualizado - Local: $localConversationId → Dify: $conversationId',
                  name: 'DifyService',
                );
              }
            }
            if (json['message_id'] != null) {
              difyMessageId = json['message_id'];
            }

            // Para no final
            if (event == 'message_end') break;
          } catch (parseError) {
            continue;
          }
        }
      }

      // SIMULA DIGITAÇÃO COM A RESPOSTA COMPLETA
      if (fullAnswer.isNotEmpty) {
        yield* _simulateTypingFromCompleteResponse(
          fullAnswer,
          difyConversationId,
          difyMessageId,
        );
      }
    } catch (error) {
      LoggerService.error('Erro no streaming com simulação: $error',
          name: 'DifyService');
      throw DomainError.unexpected;
    }
  }

  // Simula digitação da resposta completa
  Stream<DifyStreamResponse> _simulateTypingFromCompleteResponse(
    String fullText,
    String? difyConversationId,
    String? difyMessageId,
  ) async* {
    // Configura simulação
    const int wordsPerUpdate = 5; // 5 palavras por vez
    const int delayMs = 200; // 150ms entre updates

    final words = fullText.split(' ');
    String currentText = '';

    for (int i = 0; i < words.length; i += wordsPerUpdate) {
      final endIndex = (i + wordsPerUpdate).clamp(0, words.length);
      final wordBatch = words.sublist(i, endIndex);

      if (currentText.isNotEmpty) currentText += ' ';
      currentText += wordBatch.join(' ');

      final isComplete = endIndex >= words.length;

      yield DifyStreamResponse(
        content: currentText,
        isComplete: isComplete,
        metadata: isComplete
            ? DifyMetadata(
                conversationId: difyConversationId,
                messageId: difyMessageId,
              )
            : null,
      );

      // Delay entre updates (exceto no último)
      if (!isComplete) {
        await Future.delayed(const Duration(milliseconds: delayMs));
      }
    }
  }

  // Método para limpar cache de conversa (quando user faz nova conversa)
  static void clearConversationCache(String localConversationId) {
    _conversationCache.remove(localConversationId);
    LoggerService.debug('Cache de conversa limpo: $localConversationId',
        name: 'DifyService');
  }

  // Método para limpar todo o cache (logout, etc.)
  static void clearAllConversationCache() {
    _conversationCache.clear();
    LoggerService.debug('Todo cache de conversas limpo', name: 'DifyService');
  }

  // Getter para debug do cache
  static Map<String, String> get conversationCache =>
      Map.unmodifiable(_conversationCache);

  // Métodos de teste
  Future<bool> testConnection() async {
    try {
      LoggerService.debug('Testando conexão com Dify...', name: 'DifyService');

      // ignore: unused_local_variable
      final response = await httpClient.request(
        url: '$baseUrl/parameters',
        method: HttpMethod.get,
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      LoggerService.debug('Dify: Conexão testada com sucesso',
          name: 'DifyService');
      return true;
    } catch (error) {
      LoggerService.error('Erro ao testar conexão Dify: $error',
          name: 'DifyService');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAppInfo() async {
    try {
      final response = await httpClient.request(
        url: '$baseUrl/parameters',
        method: HttpMethod.get,
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      return response as Map<String, dynamic>?;
    } catch (error) {
      LoggerService.error('Erro ao obter info do app Dify: $error',
          name: 'DifyService');
      return null;
    }
  }

  // restaurar cache de uma conversa
  static void restoreConversationCache(
      String localConversationId, String difyConversationId) {
    _conversationCache[localConversationId] = difyConversationId;
    LoggerService.debug(
      'Cache restaurado - Local: $localConversationId → Dify: $difyConversationId',
      name: 'DifyService',
    );
  }

  Future<String?> getConversationTitle(
      String difyConversationId, String userId) async {
    try {
      LoggerService.debug(
        'Buscando título para conversa: $difyConversationId',
        name: 'DifyService',
      );
      final response = await httpClient.request(
        url: '$baseUrl/conversations',
        method: HttpMethod.get,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        queryParameters: {
          'user': userId,
          'limit': '1',
          'first_id': difyConversationId,
        },
      );

      if (response != null) {
        final json = response as Map<String, dynamic>;
        final conversations = json['data'] as List<dynamic>?;

        if (conversations != null && conversations.isNotEmpty) {
          final conversation = conversations.first as Map<String, dynamic>;
          final title = conversation['name'] as String?;

          LoggerService.debug(
            'Título encontrado: "$title"',
            name: 'DifyService',
          );

          return title;
        }
      }

      LoggerService.debug(
        'Nenhum título encontrado para conversa: $difyConversationId',
        name: 'DifyService',
      );

      return null;
    } catch (error) {
      LoggerService.error('Erro ao buscar título da conversa: $error',
          name: 'DifyService');
      return null;
    }
  }

  // Método para definir mapeamento manualmente (para conversas carregadas do cache)
  static void setConversationMapping(
      String localConversationId, String difyConversationId) {
    _conversationCache[localConversationId] = difyConversationId;
    LoggerService.debug(
      'Mapeamento manual criado: $localConversationId → $difyConversationId',
      name: 'DifyService',
    );
  }

  // Deleta uma conversa no Dify
  static Future<void> deleteConversation({
    required String conversationId,
    required String userId,
    required HttpClient httpClient,
    required String apiKey,
    required String baseUrl,
  }) async {
    try {
      LoggerService.debug(
        'DifyService: Deletando conversa $conversationId para usuário $userId',
        name: 'DifyService',
      );

      await httpClient.request(
        url: '$baseUrl/conversations/$conversationId',
        method: HttpMethod.delete,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: {
          'user': userId,
        },
      );

      // Remove do cache local também
      _conversationCache.remove(conversationId);

      LoggerService.debug(
        'Conversa deletada e removida do cache: $conversationId',
        name: 'DifyService',
      );
    } catch (error) {
      LoggerService.error(
        'Erro ao deletar conversa no Dify: $error',
        name: 'DifyService',
      );
      throw DomainError.networkError;
    }
  }

  // Método para verificar se tem mapeamento
  static bool hasMapping(String localConversationId) {
    return _conversationCache.containsKey(localConversationId);
  }

  // Método para obter mapeamento
  static String? getMapping(String localConversationId) {
    return _conversationCache[localConversationId];
  }

// Método para debug do cache atual
  static void printCache() {
    LoggerService.debug('=== CACHE DO DIFYSERVICE ===', name: 'DifyService');
    _conversationCache.forEach((local, dify) {
      LoggerService.debug('  $local → $dify', name: 'DifyService');
    });
    LoggerService.debug('Total: ${_conversationCache.length} mapeamentos',
        name: 'DifyService');
  }
}
