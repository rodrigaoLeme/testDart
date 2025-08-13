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

      if (response is String) {
        // Usa o streaming real do Dify
        yield* _handleRealDifyStreaming(response, conversationId);
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

  // Processa o streaming real do Dify linha por linha e
  // retorna resposta + metadata
  Stream<DifyStreamResponse> _handleRealDifyStreaming(
      String sseData, String localConversationId) async* {
    String accumulatedAnswer = '';
    String? difyConversationId;
    String? difyMessageId;

    try {
      final lines = sseData.split('\n');

      LoggerService.debug('Processando ${lines.length} linhas SSE',
          name: 'DifyService');

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final jsonString = line.substring(6).trim();

          // Pula linhas vazias ou marcador de fim
          if (jsonString.isEmpty || jsonString == '[DONE]') {
            continue;
          }

          try {
            final json = jsonDecode(jsonString);
            final event = json['event'] as String?;
            final answer = json['answer'] as String?;
            final conversationId = json['conversation_id'] as String?;
            final messageId = json['message_id'] as String?;

            // Captura e salva o conversation_id do Dify
            if (conversationId != null && conversationId.isNotEmpty) {
              difyConversationId = conversationId;
              _conversationCache[localConversationId] = conversationId;

              LoggerService.debug(
                  'Conversation ID do Dify salvo: $conversationId',
                  name: 'DifyService');
            }

            // Captura e salva o messageId do Dify
            if (messageId != null && messageId.isNotEmpty) {
              difyMessageId = messageId;

              LoggerService.debug('Message Id do Dify salvo: $messageId',
                  name: 'DifyService');
            }

            LoggerService.debug('Evento: $event, Answer: "$answer"',
                name: 'DifyService');

            // processa apenas agent_message com answer
            if (event == 'agent_message' && answer != null) {
              // Adiciona o pedaço da resposta ao texto acumulado
              accumulatedAnswer += answer;

              LoggerService.debug(
                  'Texto acumulado: "${accumulatedAnswer.length} chars"',
                  name: 'DifyService');

              // Yield resposta parcial SEM metadata (para UI)
              yield DifyStreamResponse(
                content: accumulatedAnswer,
                isComplete: false,
                metadata: null,
              );

              // *******: Delay para controlar velocidade
              await Future.delayed(const Duration(milliseconds: 30));
            }

            // finaliza quando recebe message_end
            else if (event == 'message_end') {
              LoggerService.debug('Stream finalizado - message_end recebido',
                  name: 'DifyService');

              // Yield resposta final COM metadata
              yield DifyStreamResponse(
                content: accumulatedAnswer,
                isComplete: true,
                metadata: DifyMetadata(
                  conversationId: difyConversationId,
                  messageId: difyMessageId,
                ),
              );
              break;
            }
          } catch (parseError) {
            LoggerService.debug('Erro ao parsear linha SSE: $parseError',
                name: 'DifyService');
            continue; // Ignora linhas mal formadas
          }
        }
      }

      // verifica se recebeu alguma resposta
      if (accumulatedAnswer.isEmpty) {
        LoggerService.error('Nenhuma resposta válida recebida do Dify',
            name: 'DifyService');
        throw DomainError.unexpected;
      }

      LoggerService.debug(
          'Streaming real concluído: "${accumulatedAnswer.length} chars"',
          name: 'DifyService');
    } catch (error) {
      LoggerService.error('Erro no streaming real: $error',
          name: 'DifyService');
      throw DomainError.unexpected;
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

  // Fallback para resposta blocking
  Stream<String> _handleBlockingResponse(dynamic response) async* {
    try {
      final Map<String, dynamic> json = response as Map<String, dynamic>;
      final difyResponse = DifyResponseModel.fromJson(json);

      if (difyResponse.isError) {
        throw Exception('Dify Error: ${difyResponse.answer}');
      }

      if (difyResponse.answer != null && difyResponse.answer!.isNotEmpty) {
        // Para resposta blocking, simula o efeito de digitação
        yield* _simulateTypingEffect(difyResponse.answer!);
      } else {
        throw DomainError.unexpected;
      }
    } catch (error) {
      LoggerService.error(
        'Erro ao processar resposta blocking: $error',
        name: 'DifyService',
      );
      throw DomainError.unexpected;
    }
  }

  // apenas para fallback blocking - simula digitação
  Stream<String> _simulateTypingEffect(String fullResponse) async* {
    const int typingSpeed = 50; // ms por caractere
    String currentText = '';

    for (int i = 0; i < fullResponse.length; i++) {
      currentText += fullResponse[i];
      yield currentText;

      // Delay entre caracteres (só para fallback)
      if (i < fullResponse.length - 1) {
        await Future.delayed(const Duration(milliseconds: typingSpeed));
      }
    }
  }

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
