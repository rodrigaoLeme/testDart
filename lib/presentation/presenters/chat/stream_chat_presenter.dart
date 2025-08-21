import 'dart:async';

import 'package:seven_chat_app/main/services/logger_service.dart';

import '../../../data/models/dify/dify.dart';
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

  StreamChatPresenter({
    required LoadCurrentUser loadCurrentUser,
    required CreateConversation createConversation,
    required LoadMessages loadMessages,
    required SendMessage sendMessage,
    required SendToDify sendToDify,
    required UpdateConversation updateConversation,
  })  : _loadCurrentUser = loadCurrentUser,
        _createConversation = createConversation,
        _loadMessages = loadMessages,
        _sendMessage = sendMessage,
        _sendToDify = sendToDify,
        _updateConversation = updateConversation;

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
      final messages = await _loadMessages.load(conversationId: conversationId);

      _cachedMessages = messages;
      _messagesController.sink.add(messages);

      final currentUser = await _loadCurrentUser.load();

      String? difyConversationId;

      for (final message in messages.reversed) {
        if (message.type == MessageType.assistant &&
            message.metadata['dify_conversation_id'] != null) {
          difyConversationId =
              message.metadata['dify_conversation_id'] as String;

          DifyService.restoreConversationCache(
              conversationId, difyConversationId);

          LoggerService.debug(
            'Dify conversation ID recuperado do histórico: $difyConversationId',
            name: 'ChatPresenter',
          );
          break;
        }
      }

      _currentConversation = ConversationEntity(
        id: conversationId,
        userId: currentUser?.id ?? 'anonymous-mobile',
        title: _extractTitleFromMessages(messages),
        createdAt:
            messages.isNotEmpty ? messages.first.timestamp : DateTime.now(),
        updatedAt:
            messages.isNotEmpty ? messages.last.timestamp : DateTime.now(),
        lastMessage: messages.isNotEmpty ? messages.last.content : '',
        messageCount: messages.length,
      );

      _conversationController.sink.add(_currentConversation);

      _isAnonymousSession = false;
      _anonymousSessionId = null;

      isLoading = LoadingData(isLoading: false);
      LoggerService.debug(
        'Conversa carregada com sucesso - Local: $conversationId, Dify: ${difyConversationId ?? "NOVA"}',
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

      // Busca usuário atual
      final currentUser = await _loadCurrentUser.load();
      if (currentUser == null) {
        // USUÁRIO ANÔNIMO
        LoggerService.debug(
          'Usuário não logado - criando sessão anônima',
          name: 'ChatPresenter',
        );

        _isAnonymousSession = true;
        _anonymousSessionId = 'anonymous-mobile';

        // Cria conversa temporária em memória
        _currentConversation = ConversationEntity(
            id: _anonymousSessionId!,
            userId: _anonymousSessionId!,
            title: 'Chat Anônimo',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            lastMessage: firstMessage,
            messageCount: 0);

        //_conversationController.sink.add(_currentConversation);

        // Limpa mensagens anteriores
        _cachedMessages = [];
        _messagesController.sink.add(_cachedMessages);

        // Envia primeira mensagem anônima
        await _sendAnonymousMessage(firstMessage);
      } else {
        // USUÁRIO LOGADO
        _isAnonymousSession = false;

        // Cria nova conversa
        final conversation = await _createConversation.create(
          userId: currentUser.id,
          firstMessage: firstMessage,
        );

        _currentConversation = conversation;
        _conversationController.sink.add(conversation);

        // Limpa mensagens e envia a primeira
        _cachedMessages = [];
        _messagesController.sink.add(_cachedMessages);

        // Envia primeira mensagem
        await sendMessage(firstMessage);

        LoggerService.debug(
          'Nova conversa criada: ${conversation.id}',
          name: 'ChatPresenter',
        );
      }
    } catch (error) {
      isLoading = LoadingData(isLoading: false);
      LoggerService.error(
        'Erro ao criar conversa: $error',
        name: 'ChatPresenter',
      );
      _handleError(error);
    }
  }

  // Send Message
  @override
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    if (_currentConversation == null) {
      LoggerService.info(
        'sendMessage chamado sem conversa atual - criando nova',
        name: 'ChatPresenter',
      );
      await createNewConversation(content);
      return;
    }

    LoggerService.debug(
      'Enviando mensagem na conversa: ${_currentConversation!.id}',
      name: 'ChatPresenter',
    );

    // Se é sessão anônima, usa fluxo diferente
    if (_isAnonymousSession) {
      await _sendAnonymousMessage(content);
      return;
    }

    // Fluxo normal para usuários logados
    await _sendAuthenticatedMessage(content);
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
      final userId = currentUser?.id ?? 'anonymous-user';

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

  void dispose() {
    _difyStreamSubscription?.cancel();
    _messagesController.close();
    _conversationController.close();
    _typingTextController.close();
    _isThinkingController.close();
  }
}
