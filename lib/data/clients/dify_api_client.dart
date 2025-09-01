import '../../domain/helpers/helpers.dart';
import '../../main/services/logger_service.dart';
import '../http/http.dart';
import '../models/dify/dify_conversation_model.dart';
import '../models/dify/dify_message_model.dart';

/// Client para fazer chamadas à API do Dify
class DifyApiClient {
  final String baseUrl;
  final String apiKey;
  final HttpClient httpClient;

  DifyApiClient({
    required this.baseUrl,
    required this.apiKey,
    required this.httpClient,
  });

  /// Headers padrão para todas as requisições
  Map<String, String> get _defaultHeaders => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  /// GET /conversations - Lista conversas do usuário
  Future<DifyConversationsResponse> getConversations({
    required String userId,
    String? lastId,
    int limit = 20,
    String sortBy = '-updated_at',
  }) async {
    try {
      LoggerService.debug(
        'Buscando conversas - User: $userId, Limit: $limit',
        name: 'DifyApiClient',
      );

      final queryParams = <String, dynamic>{
        'user': userId,
        'limit': limit.toString(),
        'sort_by': sortBy,
        if (lastId != null && lastId.isNotEmpty) 'last_id': lastId,
      };

      final response = await httpClient.request(
        url: '$baseUrl/conversations',
        method: HttpMethod.get,
        headers: _defaultHeaders,
        queryParameters: queryParams,
      );

      LoggerService.debug(
        'Response GET /conversations: Success',
        name: 'DifyApiClient',
      );

      // Seu HttpClient já retorna Map<String, dynamic> parseado
      if (response is Map<String, dynamic>) {
        final result = DifyConversationsResponse.fromJson(response);

        LoggerService.debug(
          'Conversas carregadas: ${result.data.length}, HasMore: ${result.hasMore}',
          name: 'DifyApiClient',
        );

        return result;
      } else {
        LoggerService.error(
          'Erro: Response não é Map. Type: ${response.runtimeType}',
          name: 'DifyApiClient',
        );
        throw DomainError.unexpected;
      }
    } catch (error) {
      LoggerService.error(
        'Exceção ao buscar conversas: $error',
        name: 'DifyApiClient',
      );
      throw DomainError.networkError;
    }
  }

  /// GET /messages - Lista mensagens de uma conversa específica
  Future<DifyMessagesResponse> getMessages({
    required String userId,
    required String conversationId,
    String? firstId,
    int limit = 20,
  }) async {
    try {
      LoggerService.debug(
        'Buscando mensagens - ConversationId: $conversationId, Limit: $limit',
        name: 'DifyApiClient',
      );

      final queryParams = <String, dynamic>{
        'user': userId,
        'conversation_id': conversationId,
        'limit': limit.toString(),
        if (firstId != null && firstId.isNotEmpty) 'first_id': firstId,
      };

      final response = await httpClient.request(
        url: '$baseUrl/messages',
        method: HttpMethod.get,
        headers: _defaultHeaders,
        queryParameters: queryParams,
      );

      LoggerService.debug(
        'Response GET /messages: Success - Type: ${response.runtimeType}',
        name: 'DifyApiClient',
      );

      // Seu HttpClient já retorna Map<String, dynamic> parseado
      if (response is Map<String, dynamic>) {
        final result = DifyMessagesResponse.fromJson(response);

        LoggerService.debug(
          'Mensagens carregadas: ${result.data.length}, HasMore: ${result.hasMore}',
          name: 'DifyApiClient',
        );

        return result;
      } else {
        LoggerService.error(
          'Erro: Response não é Map. Type: ${response.runtimeType}, Value: $response',
          name: 'DifyApiClient',
        );
        throw DomainError.unexpected;
      }
    } catch (error) {
      LoggerService.error(
        'Exceção ao buscar mensagens: $error',
        name: 'DifyApiClient',
      );
      throw DomainError.networkError;
    }
  }

  /// Testa conexão com a API do Dify
  Future<bool> testConnection() async {
    try {
      LoggerService.debug('Testando conexão com Dify...',
          name: 'DifyApiClient');

      await httpClient.request(
        url: '$baseUrl/conversations',
        method: HttpMethod.get,
        headers: _defaultHeaders,
        queryParameters: {
          'user': 'test',
          'limit': '1',
        },
      );

      LoggerService.debug(
        'Teste de conexão: SUCCESS',
        name: 'DifyApiClient',
      );

      return true;
    } catch (error) {
      LoggerService.error(
        'Erro no teste de conexão: $error',
        name: 'DifyApiClient',
      );
      return false;
    }
  }
}
