// import 'dart:async';
// import 'dart:convert';

// // TODO: Rodrigo.Leme Verificar após a resolução do login por FB
// //import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
// import 'package:seven_chat_app/main/services/logger_service.dart';

// import '../../domain/helpers/helpers.dart';
// import '../../domain/usecases/chat/send_to_dify.dart';
// import '../http/http.dart';
// import '../models/dify/dify.dart';

// class DifyService implements SendToDify {
//   final HttpClient httpClient;
//   final String apiKey;
//   final String baseUrl;

//   DifyService({
//     required this.httpClient,
//     required this.apiKey,
//     required this.baseUrl,
//   });

//   @override
//   Stream<String> sendMessage({
//     required String message,
//     required String conversationId,
//   }) async* {
//     try {
//       LoggerService.debug('Dify: Enviando mensagem...', name: 'DifyService');
//       final request = DifyRequestModel(
//         query: message,
//         user:
//             'user-${DateTime.now().millisecondsSinceEpoch}', // TODO: usar userId real
//         conversationId: '',
//         responseMode: true, // Streaming
//       );

//       final response = await httpClient.request(
//         url: '$baseUrl/chat-messages',
//         method: HttpMethod.post,
//         headers: {
//           'Authorization': 'Bearer $apiKey',
//           'Content-Type': 'application/json',
//         },
//         body: request.toJson(),
//       );

//       if (response is String) {
//         yield* _handleStreamingResponse(response);
//         //yield* _simulateStreamingFromSSESimple(response);
//       } else {
//         // Fallback para resposta não-streaming
//         yield* _handleBlockingResponse(response);
//       }
//     } catch (error, stackTrace) {
//       LoggerService.error(
//         'Erro no Dify Service: $error',
//         name: 'DifyService',
//         error: error,
//         stackTrace: stackTrace,
//       );

//       if (error.toString().contains('network') ||
//           error.toString().contains('timeout')) {
//         throw DomainError.networkError;
//       } else {
//         throw DomainError.unexpected;
//       }
//     }
//   }

//   // ✅ ALTERNATIVA: Versão mais simples sem typing effect
//   Stream<String> _simulateStreamingFromSSESimple(String sseData) async* {
//     String fullResponse = '';

//     try {
//       // Processa o SSE completo
//       final lines = sseData.split('\n');

//       for (final line in lines) {
//         if (line.startsWith('data: ')) {
//           final jsonString = line.substring(6).trim();
//           if (jsonString.isEmpty) continue;

//           try {
//             final json = jsonDecode(jsonString);

//             // Procura pela resposta no thought
//             if (json['event'] == 'agent_thought' && json['thought'] != null) {
//               final thought = json['thought'] as String;
//               if (thought.isNotEmpty) {
//                 fullResponse = thought;
//                 break;
//               }
//             }
//           } catch (_) {
//             continue;
//           }
//         }
//       }

//       if (fullResponse.isNotEmpty) {
//         yield fullResponse; // ✅ Retorna resposta completa de uma vez
//       } else {
//         throw DomainError.unexpected;
//       }
//     } catch (error) {
//       LoggerService.error('Erro ao processar SSE simples: $error',
//           name: 'DifyService');
//       throw DomainError.unexpected;
//     }
//   }

//   // Handle Streaming Response (Server-Sent Events)
//   Stream<String> _handleStreamingResponse(String sseData) async* {
//     String currentAnswer = '';

//     try {
//       // Divide por linhas
//       final lines = sseData.split('\n');

//       for (final line in lines) {
//         if (line.startsWith('data: ')) {
//           final jsonString = line.substring(6).trim(); // Remove "data: "

//           if (jsonString.isEmpty || jsonString == '[DONE]') {
//             continue;
//           }

//           try {
//             final Map<String, dynamic> json = jsonDecode(jsonString);
//             final event = json['event'] as String?;
//             final answer = json['answer'] as String?;

//             // ✅ PROCESSA DIFERENTES TIPOS DE EVENTOS:
//             if (event == 'agent_message' && answer != null) {
//               // Incrementa a resposta
//               currentAnswer += answer;
//               yield currentAnswer;
//             } else if (event == 'agent_thought' && json['thought'] != null) {
//               // Resposta completa final
//               final fullThought = json['thought'] as String;
//               if (fullThought.isNotEmpty) {
//                 currentAnswer = fullThought;
//                 yield currentAnswer;
//               }
//             } else if (event == 'message_end') {
//               // Fim do streaming
//               LoggerService.debug('Dify: Streaming concluído',
//                   name: 'DifyService');
//               if (currentAnswer.isEmpty && json['metadata'] != null) {
//                 // Se não tem resposta incremental, usa o thought final
//                 yield currentAnswer.isNotEmpty
//                     ? currentAnswer
//                     : 'Resposta recebida com sucesso!';
//               }
//               break;
//             }
//           } catch (parseError) {
//             LoggerService.error('Erro ao parsear linha SSE: $parseError',
//                 name: 'DifyService');
//             continue; // Ignora linhas mal formadas
//           }
//         }
//       }

//       // Se não recebeu nenhuma resposta, retorna erro
//       if (currentAnswer.isEmpty) {
//         throw DomainError.unexpected;
//       }
//     } catch (error) {
//       LoggerService.error('Erro no parsing do streaming: $error',
//           name: 'DifyService');
//       throw DomainError.unexpected;
//     }
//   }

//   // Handle Blocking Response (resposta única)
//   Stream<String> _handleBlockingResponse(dynamic response) async* {
//     try {
//       final Map<String, dynamic> json = response as Map<String, dynamic>;
//       final difyResponse = DifyResponseModel.fromJson(json);

//       if (difyResponse.isError) {
//         throw Exception('Dify Error: ${difyResponse.answer}');
//       }

//       if (difyResponse.answer != null && difyResponse.answer!.isNotEmpty) {
//         // Simula typing effect para resposta blocking
//         yield* _simulateTypingEffect(difyResponse.answer!);
//       } else {
//         throw DomainError.unexpected;
//       }
//     } catch (error) {
//       LoggerService.error(
//         ' Erro ao processar resposta blocking: $error',
//         name: 'DifyService',
//       );
//       throw DomainError.unexpected;
//     }
//   }

//   // Simula efeito de digitação para respostas blocking
//   Stream<String> _simulateTypingEffect(String fullResponse) async* {
//     const int typingSpeed = 50; // ms por caractere
//     String currentText = '';

//     for (int i = 0; i < fullResponse.length; i++) {
//       currentText += fullResponse[i];
//       yield currentText;

//       // Delay entre caracteres
//       await Future.delayed(const Duration(milliseconds: typingSpeed));
//     }
//   }

//   // Método para testar conexão com Dify
//   Future<bool> testConnection() async {
//     try {
//       LoggerService.debug('Testando conexão com Dify...', name: 'DifyService');

//       final response = await httpClient.request(
//         url: '$baseUrl/parameters',
//         method: HttpMethod.get,
//         headers: {
//           'Authorization': 'Bearer $apiKey',
//         },
//       );

//       LoggerService.debug('Dify: Conexão testada com sucesso',
//           name: 'DifyService');
//       return true;
//     } catch (error) {
//       LoggerService.error(
//         'Erro ao testar conexão Dify: $error',
//         name: 'DifyService',
//       );
//       return false;
//     }
//   }

//   // Método para obter informações da aplicação Dify
//   Future<Map<String, dynamic>?> getAppInfo() async {
//     try {
//       final response = await httpClient.request(
//         url: '$baseUrl/parameters',
//         method: HttpMethod.get,
//         headers: {
//           'Authorization': 'Bearer $apiKey',
//         },
//       );

//       return response as Map<String, dynamic>?;
//     } catch (error) {
//       LoggerService.error(
//         'Erro ao obter info do app Dify: $error',
//         name: 'DifyService',
//       );
//       return null;
//     }
//   }
// }
