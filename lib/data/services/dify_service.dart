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
      LoggerService.debug('Dify: Enviando mensagem...', name: 'DifyService');

      // Busca o conversation_id do Dify se já existe
      final difyConversationId = _conversationCache[conversationId] ?? '';

      LoggerService.debug(
          'ConversationId local: $conversationId, Dify: $difyConversationId',
          name: 'DifyService');

      final request = DifyRequestModel(
        query: message,
        user: userId ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: difyConversationId,
        responseMode: true,
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

      //yield* _handleBlockingResponse(response);

      if (response is String) {
        // Usa o streaming real do Dify
        //yield* _handleRealDifyStreaming(response, conversationId);

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

  Stream<DifyStreamResponse> _handleStreamingWithLocalSimulation(
      String sseData, String localConversationId) async* {
    String fullAnswer = '';
    String? difyConversationId;
    String? difyMessageId;

    try {
      // 🚀 PRIMEIRO: PROCESSA Todo O STREAMING PARA PEGAR RESPOSTA COMPLETA
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
              difyConversationId = json['conversation_id'];
              _conversationCache[localConversationId] = difyConversationId!;
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

      // 🚀 SEGUNDO: SIMULA DIGITAÇÃO COM A RESPOSTA COMPLETA
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
}
