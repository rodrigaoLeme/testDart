import 'dart:async';

import 'package:seven_chat_app/main/services/logger_service.dart';

import '../../../data/models/dify/dify.dart';
import '../../../data/repositories/dify_chat_repository.dart';
import '../../../data/services/dify_service.dart';
import '../../../domain/entities/chat/chat.dart';
import '../../../domain/helpers/helpers.dart';
import '../../../domain/usecases/chat/chat.dart';
import '../../../domain/usecases/user/load_current_user.dart';
import '../../../main/routes_app.dart';
import '../../../ui/helpers/helpers.dart';
import '../../../ui/mixins/navigation_data.dart';
import '../../mixins/mixins.dart';
import './chat_presenter.dart';

class StreamChatPresenter
    with LoadingManager, NavigationManager, UIErrorManager
    implements ChatPresenter {
  final LoadCurrentUser _loadCurrentUser;
  final CreateConversation _createConversation;
  final LoadMessages _loadMessages;
  final SendMessage _sendMessage;
  final SendToDify _sendToDify;
  final UpdateConversation _updateConversation;
  final DifyChatRepository _difyChatRepository;

  StreamChatPresenter({
    required LoadCurrentUser loadCurrentUser,
    required CreateConversation createConversation,
    required LoadMessages loadMessages,
    required SendMessage sendMessage,
    required SendToDify sendToDify,
    required UpdateConversation updateConversation,
    required DifyChatRepository difyChatRepository,
  })  : _loadCurrentUser = loadCurrentUser,
        _createConversation = createConversation,
        _loadMessages = loadMessages,
        _sendMessage = sendMessage,
        _sendToDify = sendToDify,
        _updateConversation = updateConversation,
        _difyChatRepository = difyChatRepository;

  // Stream Controllers
  final StreamController<List<MessageEntity>> _messagesController =
      StreamController<List<MessageEntity>>.broadcast();

  final StreamController<ConversationEntity?> _conversationController =
      StreamController<ConversationEntity?>.broadcast();

  final StreamController<String> _typingTextController =
      StreamController<String>.broadcast();

  final StreamController<bool> _isThinkingController =
      StreamController<bool>.broadcast();

  // Cache local
  List<MessageEntity> _cachedMessages = [];
  ConversationEntity? _currentConversation;
  bool _isTyping = false;
  bool _isThinking = false;
  StreamSubscription? _difyStreamSubscription;

  // Controle da sessão anônima
  bool _isAnonymousSession = false;
  String? _anonymousSessionId;

  // Getters
  @override
  Stream<List<MessageEntity>> get messagesStream => _messagesController.stream;

  @override
  Stream<ConversationEntity?> get currentConversationStream =>
      _conversationController.stream;

  @override
  Stream<String> get typingTextStream => _typingTextController.stream;

  @override
  Stream<bool> get isThinkingStream => _isThinkingController.stream;

  @override
  List<MessageEntity> get messages => _cachedMessages;

  @override
  ConversationEntity? get currentConversation => _currentConversation;

  @override
  bool get isTyping => _isTyping;

  @override
  bool get isThinking => _isThinking;

  // LOAD CONVERSATION EXISTENTE (apenas usuários logados)
  @override
  Future<void> loadConversation(String conversationId) async {
    try {
      isLoading = LoadingData(isLoading: true);
      LoggerService.debug(
        'Carregando conversa: $conversationId',
        name: 'ChatPresenter',
      );

      // Carrega mensagens da conversa
      //final messages = await _loadMessages.load(conversationId: conversationId);
      final messages = await _difyChatRepository.getMessages(
        conversationId: conversationId,
      );

      _cachedMessages = messages;
      _messagesController.sink.add(messages);

      // Busca dados da conversa também
      final conversations =
          await _difyChatRepository.loadConversationsFromCache();
      final conversation = conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => throw Exception('Conversa não encontrada'),
      );

      _currentConversation = conversation.toEntity();
      _conversationController.sink.add(_currentConversation);

      isLoading = LoadingData(isLoading: false);
      LoggerService.debug(
        'Conversa carregada: ${messages.length} mensagens',
        name: 'ChatPresenter',
      );
    } catch (error) {
      isLoading = LoadingData(isLoading: false);
      LoggerService.error(
        'Erro ao carregar conversa: $error',
        name: 'ChatPresenter',
      );
      _handleError(error);
    }
  }

  // CREATE NEW CONVERSATION
  @override
  Future<void> createNewConversation(String firstMessage) async {
    try {
      LoggerService.debug(
        'Criando nova conversa...',
        name: 'ChatPresenter',
      );

      // Cria conversa temporária (sem título ainda)
      final tempConversation = ConversationEntity(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'pending',
        title: 'Nova conversa',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messageCount: 0,
        metadata: {'awaiting_dify_title': true},
      );

      _currentConversation = tempConversation;
      _conversationController.sink.add(_currentConversation);

      // Limpa mensagens
      _cachedMessages = [];
      _messagesController.sink.add(_cachedMessages);

      // Envia primeira mensagem e aguarda resposta completa do Dify
      await sendMessage(firstMessage);
    } catch (error) {
      isLoading = LoadingData(isLoading: false);
      LoggerService.error(
        'Erro ao criar conversa: $error',
        name: 'ChatPresenter',
      );
      _handleError(error);
    }
  }

  Future<void> _sendFirstMessage(String content) async {
    if (content.trim().isEmpty || _currentConversation == null) return;

    try {
      LoggerService.debug('Enviando primeira mensagem...',
          name: 'ChatPresenter');

      // 1. Adiciona mensagem do usuário (apenas na UI)
      final userMessage = MessageEntity(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _currentConversation!.id,
        content: content.trim(),
        type: MessageType.user,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );

      _cachedMessages.add(userMessage);
      _messagesController.sink.add(List.from(_cachedMessages));

      // 2. Inicia estado "pensando"
      _startThinkingState();

      // 3. Busca o user ID
      final currentUser = await _loadCurrentUser.load();
      final userId = currentUser?.id ?? 'anonymous-mobile';

      // 4. Variáveis para capturar dados do Dify
      String fullResponse = '';
      DifyMetadata? finalMetadata;

      _difyStreamSubscription?.cancel();
      _difyStreamSubscription = _sendToDify
          .sendMessage(
        message: content.trim(),
        conversationId: _currentConversation!.id,
        userId: userId,
      )
          .listen(
        (difyResponse) {
          if (_isThinking && difyResponse.content.trim().isNotEmpty) {
            _stopThinkingState();
            _startTypingEffect();
          }

          fullResponse = difyResponse.content;

          if (!_isThinking) {
            _typingTextController.sink.add(difyResponse.content);
          }

          if (difyResponse.isComplete && difyResponse.metadata != null) {
            finalMetadata = difyResponse.metadata;
          }
        },
        onDone: () async {
          LoggerService.debug('Primera mensagem finalizada, processando...',
              name: 'ChatPresenter');
          await _completeFirstConversation(
              fullResponse, finalMetadata, userId, content);
        },
        onError: (error) {
          LoggerService.error('Erro na primeira mensagem: $error',
              name: 'ChatPresenter');
          _stopThinkingState();
          _stopTypingEffect();
          _handleError(error);
        },
      );
    } catch (error) {
      LoggerService.error('Erro ao enviar primeira mensagem: $error',
          name: 'ChatPresenter');
      _stopThinkingState();
      _stopTypingEffect();
      _handleError(error);
    }
  }

  Future<void> _completeFirstConversation(
    String fullResponse,
    DifyMetadata? metadata,
    String userId,
    String firstMessage,
  ) async {
    try {
      _stopTypingEffect();

      if (fullResponse.trim().isEmpty) {
        throw DomainError.unexpected;
      }

      // 1. Cria mensagem do assistente
      final assistantMessage = MessageEntity(
        id: 'assistant_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _currentConversation!.id,
        content: fullResponse,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        metadata: metadata?.toMap() ?? {},
      );

      _cachedMessages.add(assistantMessage);
      _messagesController.sink.add(List.from(_cachedMessages));

      // 2. Agora atualiza a conversa com dados reais do Dify
      if (metadata?.conversationId != null) {
        await _updateConversationWithDifyData(
            metadata!.conversationId!, userId, firstMessage);
      }
    } catch (error) {
      LoggerService.error('Erro ao completar primeira conversa: $error',
          name: 'ChatPresenter');
      _handleError(error);
    }
  }

  Future<void> _updateConversationWithDifyData(
      String difyConversationId, String userId, String firstMessage) async {
    try {
      // 1. Tenta buscar o título do Dify
      String? difyTitle;
      if (_sendToDify is DifyService) {
        final difyService = _sendToDify;
        difyTitle =
            await difyService.getConversationTitle(difyConversationId, userId);
      }

      // 2. Cria conversa definitiva com título do Dify ou fallback
      final finalConversation = ConversationEntity(
        id: difyConversationId, // Usa o ID do Dify como ID principal
        userId: userId,
        title: difyTitle ?? _generateFallbackTitle(firstMessage),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messageCount: 0,
      );

      // 3. Atualiza o presenter
      _currentConversation = finalConversation;
      _conversationController.sink.add(finalConversation);

      // 4. Atualiza as mensagens com o conversation_id correto
      _cachedMessages = _cachedMessages
          .map((msg) => MessageEntity(
                id: msg.id,
                conversationId:
                    finalConversation.id, // Atualiza para o ID do Dify
                content: msg.content,
                type: msg.type,
                timestamp: msg.timestamp,
                status: msg.status,
                metadata: msg.metadata,
              ))
          .toList();

      _messagesController.sink.add(List.from(_cachedMessages));

      LoggerService.debug(
        'Conversa atualizada com dados do Dify: ${finalConversation.id} - "${finalConversation.title}"',
        name: 'ChatPresenter',
      );

      // 5. Se não conseguiu pegar o título, agenda uma busca posterior
      if (difyTitle == null) {
        _scheduleTitleRefresh(difyConversationId, userId);
      }
    } catch (error) {
      LoggerService.error(
          'Erro ao atualizar conversa com dados do Dify: $error',
          name: 'ChatPresenter');
      // Se falhar, mantém a conversa temporária funcionando
    }
  }

  // Send Message
  @override
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Se não tem conversa, cria uma temporária
    if (_currentConversation == null) {
      await createNewConversation(content);
      return;
    }

    try {
      LoggerService.debug(
        'Enviando mensagem: ${content.length > 20 ? content.substring(0, 20) : content}...',
        name: 'ChatPresenter',
      );

      // 1. Adiciona mensagem do usuário (apenas na UI)
      final userMessage = MessageEntity(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _currentConversation!.id,
        content: content.trim(),
        type: MessageType.user,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );

      _cachedMessages.add(userMessage);
      _messagesController.sink.add(List.from(_cachedMessages));

      // 2. Inicia "pensando"
      _startThinkingState();

      // 3. Busca userId
      final currentUser = await _loadCurrentUser.load();
      final userId = currentUser?.id ?? 'anonymous-mobile';

      // 4. Stream do Dify
      String fullResponse = '';
      DifyMetadata? finalMetadata;

      _difyStreamSubscription?.cancel();
      _difyStreamSubscription = _sendToDify
          .sendMessage(
        message: content.trim(),
        conversationId: _currentConversation!.id,
        userId: userId,
      )
          .listen(
        (difyResponse) {
          if (_isThinking && difyResponse.content.trim().isNotEmpty) {
            _stopThinkingState();
            _startTypingEffect();
          }

          fullResponse = difyResponse.content;

          if (!_isThinking) {
            _typingTextController.sink.add(difyResponse.content);
          }

          if (difyResponse.isComplete && difyResponse.metadata != null) {
            finalMetadata = difyResponse.metadata;
          }
        },
        onDone: () async {
          await _completeMessage(fullResponse, finalMetadata, userId, content);
        },
        onError: (error) {
          LoggerService.error('Erro no stream: $error', name: 'ChatPresenter');
          _stopThinkingState();
          _stopTypingEffect();
          _handleError(error);
        },
      );
    } catch (error) {
      LoggerService.error('Erro ao enviar mensagem: $error',
          name: 'ChatPresenter');
      _stopThinkingState();
      _stopTypingEffect();
      _handleError(error);
    }
  }

  // Envio de mensagem anônima (apenas em memória)
  Future<void> _sendAnonymousMessage(String content) async {
    try {
      LoggerService.debug(
        'Enviando mensagem anônima: ${content.length > 20 ? content.substring(0, 20) : content}...',
        name: 'ChatPresenter',
      );

      // 1. Cria mensagem do usuário em memória
      final userMessage = MessageEntity(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _anonymousSessionId!,
        content: content.trim(),
        type: MessageType.user,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );

      _cachedMessages.add(userMessage);
      _messagesController.sink.add(List.from(_cachedMessages));

      // 2. Inicia estado "pensando"
      _startThinkingState();

      // 3. Envia para Dify com ID anônimo
      String fullResponse = '';
      DifyMetadata? finalMetadata;

      _difyStreamSubscription?.cancel();
      _difyStreamSubscription = _sendToDify
          .sendMessage(
        message: content.trim(),
        conversationId: _anonymousSessionId!,
        userId: _anonymousSessionId!,
      )
          .listen(
        (difyResponse) {
          // Se é primeira resposta, para o "pensando" e inicia "digitando"
          if (_isThinking && difyResponse.content.trim().isNotEmpty) {
            _stopThinkingState();
            _startTypingEffect();
          }

          LoggerService.debug(
              'Recebendo resposta anônima: ${difyResponse.content.substring(0, 50)}...',
              name: 'ChatPresenter');

          fullResponse = difyResponse.content;

          // Só envia para o stream se não está mais pensando
          if (!_isThinking) {
            _typingTextController.sink.add(difyResponse.content);
          }

          if (difyResponse.isComplete && difyResponse.metadata != null) {
            finalMetadata = difyResponse.metadata;
          }
        },
        onDone: () async {
          LoggerService.debug('Stream anônimo finalizado',
              name: 'ChatPresenter');

          await _completeAnonymousAssistantMessage(fullResponse, finalMetadata);
        },
        onError: (error) {
          LoggerService.error('🔴 Erro no stream anônimo: $error',
              name: 'ChatPresenter');
          _stopThinkingState();
          _stopTypingEffect();
          _handleError(error);
        },
      );
    } catch (error) {
      LoggerService.error(
        'Erro ao enviar mensagem anônima: $error',
        name: 'ChatPresenter',
      );
      _stopThinkingState();
      _stopTypingEffect();
      _handleError(error);
    }
  }

  // Novo método para criar conversa após resposta do Dify
  Future<void> _createConversationFromDifyResponse({
    required String userId,
    required String userMessage,
    required String difyResponse,
    required DifyMetadata difyMetadata,
  }) async {
    try {
      LoggerService.debug(
          'Criando conversa com dados do Dify: ${difyMetadata.conversationId}',
          name: 'ChatPresenter');

      // Se estamos usando DifyChatRepository
      final conversation =
          await _difyChatRepository.createConversationFromDifyResponse(
        userId: userId,
        difyConversationId: difyMetadata.conversationId!,
        difyTitle: _generateTitleFromMessage(
            userMessage), // Ou usar título do Dify se disponível
        firstMessage: userMessage,
        difyResponse: difyResponse,
      );

      // Atualiza conversa atual
      _currentConversation = conversation;
      _conversationController.sink.add(conversation);

      // Recria mensagens com IDs corretos (do Dify)
      await _recreateMessagesWithDifyIds(
        conversationId: conversation.id,
        userMessage: userMessage,
        difyResponse: difyResponse,
        difyMetadata: difyMetadata,
      );

      LoggerService.debug('Nova conversa criada: ${conversation.id}',
          name: 'ChatPresenter');
    } catch (error) {
      LoggerService.error('Erro ao criar conversa com dados do Dify: $error',
          name: 'ChatPresenter');
    }
  }

  // Mensagem autenticada
  Future<void> _sendAuthenticatedMessage(String content) async {
    try {
      LoggerService.debug(
        'Enviando mensagem autenticada: ${content.length > 20 ? content.substring(0, 20) : content}...',
        name: 'ChatPresenter',
      );

      // 1. Adiciona mensagem do usuário no Firebase
      final userMessage = await _sendMessage.send(
        conversationId: _currentConversation!.id,
        content: content.trim(),
        type: MessageType.user,
      );

      _cachedMessages.add(userMessage);
      _messagesController.sink.add(List.from(_cachedMessages));

      // 2. Inicia estado "pensando"
      _startThinkingState();

      // 3. Busca o user ID real
      final currentUser = await _loadCurrentUser.load();
      final userId = currentUser?.id ?? 'anonymous-mobile';

      LoggerService.debug(
        'Enviando para Dify - ConversationID: ${_currentConversation!.id}, UserID: $userId',
        name: 'ChatPresenter',
      );

      // Variáveis para capturar dados do Dify
      String fullResponse = '';
      DifyMetadata? finalMetadata;

      _difyStreamSubscription?.cancel();
      _difyStreamSubscription = _sendToDify
          .sendMessage(
        message: content.trim(),
        conversationId: _currentConversation!.id,
        userId: userId,
      )
          .listen(
        (difyResponse) {
          if (_isThinking && difyResponse.content.trim().isNotEmpty) {
            _stopThinkingState();
            _startTypingEffect();
          }

          LoggerService.debug(
              'Recebendo resposta: ${difyResponse.content.substring(0, 50)}...',
              name: 'ChatPresenter');

          fullResponse = difyResponse.content;

          if (!_isThinking) {
            _typingTextController.sink.add(difyResponse.content);
          }

          if (difyResponse.isComplete && difyResponse.metadata != null) {
            finalMetadata = difyResponse.metadata;
          }
        },
        onDone: () async {
          LoggerService.debug('Stream finalizado, salvando resposta',
              name: 'ChatPresenter');

          await _completeAssistantMessage(fullResponse, finalMetadata);
        },
        onError: (error) {
          LoggerService.error('🔴 Erro no stream: $error',
              name: 'ChatPresenter');
          _stopThinkingState();
          _stopTypingEffect();
          _handleError(error);
        },
      );
    } catch (error) {
      LoggerService.error(
        'Erro ao enviar mensagem: $error',
        name: 'ChatPresenter',
      );
      _stopThinkingState();
      _stopTypingEffect();
      _handleError(error);
    }
  }

  // Helper para recriar mensagens com IDs corretos
  Future<void> _recreateMessagesWithDifyIds({
    required String conversationId,
    required String userMessage,
    required String difyResponse,
    required DifyMetadata difyMetadata,
  }) async {
    try {
      // Limpa mensagens temporárias
      _cachedMessages.clear();

      // Cria mensagem do usuário com ID correto
      final userMessageEntity = MessageEntity(
        id: '${difyMetadata.messageId}_user', // Base no ID do Dify
        conversationId: conversationId,
        content: userMessage,
        type: MessageType.user,
        timestamp: DateTime.now().subtract(const Duration(seconds: 1)),
        status: MessageStatus.sent,
        metadata: {
          'dify_conversation_id': difyMetadata.conversationId,
          'dify_message_id': difyMetadata.messageId,
        },
      );

      // Cria mensagem do assistente
      final assistantMessageEntity = MessageEntity(
        id: '${difyMetadata.messageId}_assistant',
        conversationId: conversationId,
        content: difyResponse,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        metadata: {
          'dify_conversation_id': difyMetadata.conversationId,
          'dify_message_id': difyMetadata.messageId,
        },
      );

      _cachedMessages.addAll([userMessageEntity, assistantMessageEntity]);

      // Salva no repository para cache usando métodos públicos
      await _difyChatRepository.addMessagesToCache(
        conversationId,
        [userMessageEntity, assistantMessageEntity],
      );

      _messagesController.sink.add(List.from(_cachedMessages));

      LoggerService.debug('Mensagens recriadas com IDs do Dify',
          name: 'ChatPresenter');
    } catch (error) {
      LoggerService.error('Erro ao recriar mensagens: $error',
          name: 'ChatPresenter');
    }
  }

  String _generateTitleFromMessage(String message) {
    if (message.length <= 50) return message;
    return '${message.substring(0, 47)}...';
  }

  // Completa mensagem do assistente anônimo
  Future<void> _completeAnonymousAssistantMessage(
    String fullResponse,
    DifyMetadata? metadata,
  ) async {
    try {
      _stopTypingEffect();

      if (fullResponse.trim().isEmpty) {
        throw DomainError.unexpected;
      }

      // Cria mensagem do assistente em memória
      final assistantMessage = MessageEntity(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _anonymousSessionId!,
        content: fullResponse.trim(),
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        metadata: metadata!.toMap(),
      );

      _cachedMessages.add(assistantMessage);
      _messagesController.sink.add(List.from(_cachedMessages));

      LoggerService.debug('Resposta anônima completa adicionada',
          name: 'ChatPresenter');
    } catch (error) {
      LoggerService.error('Erro ao completar mensagem anônima: $error',
          name: 'ChatPresenter');
      _handleError(error);
    }
  }

  Future<void> _completeMessage(
    String fullResponse,
    DifyMetadata? metadata,
    String userId,
    String userMessage,
  ) async {
    try {
      _stopTypingEffect();

      if (fullResponse.trim().isEmpty) {
        throw DomainError.unexpected;
      }

      // 1. Cria mensagem do assistente
      final assistantMessage = MessageEntity(
        id: 'assistant_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _currentConversation!.id,
        content: fullResponse,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        metadata: metadata?.toMap() ?? {},
      );

      _cachedMessages.add(assistantMessage);
      _messagesController.sink.add(List.from(_cachedMessages));

      // 2. Se é a primeira conversa, atualiza com dados do Dify
      final isFirstConversation =
          _currentConversation!.metadata['awaiting_dify_title'] == true;

      if (isFirstConversation && metadata?.conversationId != null) {
        await _finalizeConversationWithDifyData(
            metadata!.conversationId!, userId, userMessage);
      }
      LoggerService.debug('Mensagem completada', name: 'ChatPresenter');
    } catch (error) {
      LoggerService.error('Erro ao completar mensagem: $error',
          name: 'ChatPresenter');
      _handleError(error);
    }
  }

  Future<void> _finalizeConversationWithDifyData(
    String difyConversationId,
    String userId,
    String firstMessage,
  ) async {
    try {
      LoggerService.debug(
        'Atualizando para conversa real: $difyConversationId',
        name: 'ChatPresenter',
      );

      // 1. Atualiza conversa
      _currentConversation = _currentConversation!.copyWith(
        id: difyConversationId,
        userId: userId,
        title: "Carregando título...",
        metadata: {
          'dify_conversation_id': difyConversationId,
          'awaiting_dify_title': false,
          'title_loading': true,
        },
      );

      // 2. Atualiza mensagens com novo ID
      _cachedMessages = _cachedMessages
          .map((msg) => MessageEntity(
                id: msg.id,
                conversationId: difyConversationId,
                content: msg.content,
                type: msg.type,
                timestamp: msg.timestamp,
                status: msg.status,
                metadata: msg.metadata,
              ))
          .toList();

      // 3. Notifica mudanças
      _conversationController.sink.add(_currentConversation);
      _messagesController.sink.add(List.from(_cachedMessages));

      // 4. Busca o título real do Dify
      _fetchAndUpdateTitle(difyConversationId, userId, firstMessage);

      LoggerService.debug(
        'Conversa finalizada: $difyConversationId - "${_currentConversation!.title}"',
        name: 'ChatPresenter',
      );
    } catch (error) {
      LoggerService.error('Erro ao finalizar conversa: $error',
          name: 'ChatPresenter');
    }
  }

  void _fetchAndUpdateTitle(
      String difyConversationId, String userId, String firstMessage) {
    // Busca título em background
    Timer(const Duration(seconds: 2), () async {
      try {
        if (_sendToDify is DifyService) {
          final difyService = _sendToDify;
          final title = await difyService.getConversationTitle(
              difyConversationId, userId);

          // Se conseguiu pegar o título e ainda é a mesma conversa
          if (title != null && _currentConversation?.id == difyConversationId) {
            _currentConversation = _currentConversation!.copyWith(
              title: title,
              metadata: {
                ..._currentConversation!.metadata,
                'title_loading': false,
                'title_from_dify': true,
              },
            );

            _conversationController.sink.add(_currentConversation);

            LoggerService.debug('Título do Dify carregado: "$title"',
                name: 'ChatPresenter');
          } else {
            // Fallback para título da pergunta
            final fallbackTitle = _generateFallbackTitle(firstMessage);

            _currentConversation = _currentConversation!.copyWith(
              title: fallbackTitle,
              metadata: {
                ..._currentConversation!.metadata,
                'title_loading': false,
                'title_from_dify': false,
              },
            );

            _conversationController.sink.add(_currentConversation);

            LoggerService.debug('Usando título fallback: "$fallbackTitle"',
                name: 'ChatPresenter');
          }
        }
      } catch (error) {
        LoggerService.debug('Erro ao buscar título: $error',
            name: 'ChatPresenter');

        // Usar fallback se falhar
        final fallbackTitle = _generateFallbackTitle(firstMessage);
        _currentConversation = _currentConversation!.copyWith(
          title: fallbackTitle,
          metadata: {
            ..._currentConversation!.metadata,
            'title_loading': false,
            'title_from_dify': false,
          },
        );
        _conversationController.sink.add(_currentConversation);
      }
    });
  }

  Future<String?> _getTitleWithRetry(
      String difyConversationId, String userId) async {
    if (_sendToDify is! DifyService) return null;

    final difyService = _sendToDify;

    // Tenta 3 vezes com delay
    for (int i = 0; i < 3; i++) {
      try {
        final title =
            await difyService.getConversationTitle(difyConversationId, userId);
        if (title != null) return title;

        // Aguarda antes de tentar novamente
        if (i < 2) await Future.delayed(Duration(seconds: 1 + i));
      } catch (error) {
        LoggerService.debug('Tentativa ${i + 1} falhou: $error',
            name: 'ChatPresenter');
      }
    }

    return null;
  }

  // COMPLETE ASSISTANT MESSAGE
  Future<void> _completeAssistantMessage(
    String fullResponse,
    DifyMetadata? metadata,
  ) async {
    try {
      _stopTypingEffect();

      if (fullResponse.trim().isEmpty) {
        throw DomainError.unexpected;
      }

      final metadataMap = metadata?.toMap() ?? <String, dynamic>{};

      if (metadata != null) {
        metadataMap.addAll(metadata.toMap());

        // Adiciona os IDs do Dify explicitamente
        if (metadata.conversationId != null) {
          metadataMap['dify_conversation_id'] = metadata.conversationId;
        }
        if (metadata.messageId != null) {
          metadataMap['dify_message_id'] = metadata.messageId;
        }
      }

      // Salva mensagem com metadata
      final assistantMessage = await _sendMessage.send(
        conversationId: _currentConversation!.id,
        content: fullResponse.trim(),
        type: MessageType.assistant,
        metadata: metadataMap.isNotEmpty ? metadataMap : null,
      );

      _cachedMessages.add(assistantMessage);
      _messagesController.sink.add(List.from(_cachedMessages));

      // Atualiza conversa com última mensagem
      if (_currentConversation != null) {
        final updatedConversation = _currentConversation!.copyWith(
          updatedAt: DateTime.now(),
          messageCount: _cachedMessages.length,
          lastMessage: fullResponse.trim(),
        );

        await _updateConversation.update(updatedConversation);
        _currentConversation = updatedConversation;
        _conversationController.sink.add(updatedConversation);
      }

      LoggerService.debug(
        'Resposta salva com metadata: ${metadataMap.keys}',
        name: 'ChatPresenter',
      );
    } catch (error) {
      LoggerService.error(
        'Erro ao completar resposta do assistente: $error',
        name: 'ChatPresenter',
      );
      _handleError(error);
    }
  }

  // MÉTODOS: Controle de estados de "pensando" e "digitando"
  void _startThinkingState() {
    _isThinking = true;
    _isTyping = false;
    _isThinkingController.sink.add(true);
    _typingTextController.sink.add(''); // Limpa texto de digitação
    LoggerService.debug(
      'IA iniciou estado "pensando"...',
      name: 'ChatPresenter',
    );
  }

  void _stopThinkingState() {
    _isThinking = false;
    _isThinkingController.sink.add(false);
    LoggerService.debug(
      'IA parou de "pensar"',
      name: 'ChatPresenter',
    );
  }

  // TYPING EFFECTS
  void _startTypingEffect() {
    _isTyping = true;
    LoggerService.debug(
      'Iniciando efeito digitando...',
      name: 'ChatPresenter',
    );
  }

  void _stopTypingEffect() {
    _isTyping = false;
    _typingTextController.sink.add(''); // Limpa texto de digitação
    LoggerService.debug(
      'Parando efeito digitando',
      name: 'ChatPresenter',
    );
  }

  // paginação
  @override
  Future<void> loadMoreMessages() async {
    // TODO: @rodrigo.leme Implementar paginação de mensagens
    LoggerService.debug(
      'Load more messages - TODO',
      name: 'ChatPresenter',
    );
  }

  // Voltar
  @override
  void goBack() {
    LoggerService.debug('CHAMANDO GOBACK - Stack trace:',
        name: 'ChatPresenter');
    _difyStreamSubscription?.cancel();
    navigateTo = NavigationData(route: Routes.home, clear: true);
  }

  // ERROR HANDLING
  void _handleError(dynamic error) {
    if (error is DomainError) {
      switch (error) {
        case DomainError.networkError:
          mainError = UIError.networkError;
          break;
        case DomainError.accessDenied:
          mainError = UIError.invalidCredentials;
          break;
        default:
          mainError = UIError.unexpected;
      }
    } else {
      mainError = UIError.unexpected;
    }
  }

  @override
  void clearCurrentConversation() {
    // Cancela stream do Dify se existir
    _difyStreamSubscription?.cancel();

    // Limpar cache do Dify se havia conversa ativa
    if (_currentConversation != null) {
      // Assumindo que você vai importar DifyService
      DifyService.clearConversationCache(_currentConversation!.id);
    }

    // Limpa conversa atual
    _currentConversation = null;
    _conversationController.sink.add(null);

    // Limpa mensagens
    _cachedMessages = [];
    _messagesController.sink.add([]);

    // Para efeito de digitação
    _stopThinkingState();
    _stopTypingEffect();

    // Limpa flags de sessão anônima
    _isAnonymousSession = false;
    _anonymousSessionId = null;

    LoggerService.debug('Conversa atual limpa', name: 'ChatPresenter');
  }

  // Método que retorna título das mensagens
  String _extractTitleFromMessages(List<MessageEntity> messages) {
    if (messages.isEmpty) return 'Conversa';

    // Procura primeira mensagem do usuário
    final firstUserMessage = messages.firstWhere(
      (m) => m.type == MessageType.user,
      orElse: () => messages.first,
    );

    final content = firstUserMessage.content;
    // Limita o título a 50 caracteres
    return content.length > 50 ? '${content.substring(0, 47)}...' : content;
  }

  String _generateFallbackTitle(String firstMessage) {
    return firstMessage.length > 45
        ? '${firstMessage.substring(0, 45)}...'
        : firstMessage;
  }

  void _scheduleTitleRefresh(String difyConversationId, String userId) {
    // Agenda uma busca do título em 3 segundos (tempo para o Dify processar)
    Timer(const Duration(seconds: 3), () async {
      try {
        if (_sendToDify is DifyService) {
          final difyService = _sendToDify;
          final title = await difyService.getConversationTitle(
              difyConversationId, userId);

          if (title != null && _currentConversation?.id == difyConversationId) {
            // Atualiza apenas o título
            _currentConversation = _currentConversation!.copyWith(title: title);
            _conversationController.sink.add(_currentConversation);

            LoggerService.debug('Título atualizado via timer: "$title"',
                name: 'ChatPresenter');
          }
        }
      } catch (error) {
        LoggerService.debug('Erro ao buscar título via timer: $error',
            name: 'ChatPresenter');
        // Se falhar, mantém o título fallback
      }
    });
  }

  void dispose() {
    _difyStreamSubscription?.cancel();
    _messagesController.close();
    _conversationController.close();
    _typingTextController.close();
    _isThinkingController.close();
  }
}
