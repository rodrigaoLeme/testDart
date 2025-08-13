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

  // LOAD CONVERSATION EXISTENTE
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

      // TODO: Carregar dados da conversa também
      // final conversation = await _loadConversation.load(conversationId);
      // _currentConversation = conversation;
      // _conversationController.sink.add(conversation);

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

      // Busca usuário atual
      final currentUser = await _loadCurrentUser.load();
      if (currentUser == null) {
        throw DomainError.accessDenied;
      }

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
    if (content.trim().isEmpty || _currentConversation == null) return;

    try {
      LoggerService.debug(
        'Enviando mensagem: ${content.length > 20 ? content.substring(0, 20) : content}...',
        name: 'ChatPresenter',
      );

      // 1. Adiciona mensagem do usuário
      final userMessage = await _sendMessage.send(
        conversationId: _currentConversation!.id,
        content: content.trim(),
        type: MessageType.user,
      );

      _cachedMessages.add(userMessage);
      _messagesController.sink.add(List.from(_cachedMessages));

      // 2. Inicia estado "pensando" antes do Dify
      _startThinkingState();

      // 3. Busca o user ID real
      final currentUser = await _loadCurrentUser.load();
      final userId = currentUser?.id ??
          'anonymous-${DateTime.now().millisecondsSinceEpoch}';

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
          // e primeira resposta, para o "pensando" e inicia "digitando"
          if (_isThinking && difyResponse.content.trim().isNotEmpty) {
            _stopThinkingState();
            _startTypingEffect();
          }

          LoggerService.debug(
              '🟢 Recebendo resposta: ${difyResponse.content.substring(0, 50)}...',
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
          LoggerService.debug('🟢 Stream finalizado, salvando resposta',
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

    LoggerService.debug('Conversa atual limpa', name: 'ChatPresenter');
  }

  void dispose() {
    _difyStreamSubscription?.cancel();
    _messagesController.close();
    _conversationController.close();
    _typingTextController.close();
    _isThinkingController.close();
  }
}
