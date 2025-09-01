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
  final SendToDify _sendToDify;

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
        _sendToDify = sendToDify,
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

      // Verifica se precisa restaurar contexto do Dify
      final difyConversationId =
          _currentConversation!.metadata['dify_conversation_id'] as String?;
      if (difyConversationId != null &&
          !DifyService.conversationCache.containsKey(conversationId)) {
        // Restaura o mapeamento no cache do Dify
        DifyService.updateConversationCache('temp', conversationId);
        // Ou define diretamente se souber o difyConversationId
        LoggerService.debug(
          'Restaurando contexto do Dify para conversa: $conversationId',
          name: 'ChatPresenter',
        );
      }

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

      // salva no cache, não apenas primeira conversa
      await _difyChatRepository.addMessagesToCache(
          _currentConversation!.id, _cachedMessages);

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

      //final tempConversationId = _currentConversation!.id;

      if (userId == 'anonymous-mobile') {
        return;
      }

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

      // // 3. Atualiza cache do Dify para manter contexto
      // DifyService.updateConversationCache(
      //     tempConversationId, difyConversationId);

      LoggerService.debug(
          'Salvando conversa no cache: ${_currentConversation!.id}',
          name: 'ChatPresenter');
      await _difyChatRepository
          .updateConversationInCache(_currentConversation!);
      LoggerService.debug('Conversa salva no cache com sucesso',
          name: 'ChatPresenter');
      await _difyChatRepository.addMessagesToCache(
          difyConversationId, _cachedMessages);

      // _conversationController.sink.add(_currentConversation);
      // _messagesController.sink.add(List.from(_cachedMessages));

      // LoggerService.debug(
      //     'Salvando conversa no cache: ${_currentConversation!.id}',
      //     name: 'ChatPresenter');
      // await _difyChatRepository
      //     .updateConversationInCache(_currentConversation!);
      // LoggerService.debug('Conversa salva no cache com sucesso',
      //     name: 'ChatPresenter');

      // 4. Busca o título real do Dify
      _fetchAndUpdateTitle(
          difyConversationId, userId, firstMessage, _cachedMessages);

      LoggerService.debug(
        'Conversa finalizada: $difyConversationId - "${_currentConversation!.title}"',
        name: 'ChatPresenter',
      );
    } catch (error) {
      LoggerService.error('Erro ao finalizar conversa: $error',
          name: 'ChatPresenter');
    }
  }

  void _fetchAndUpdateTitle(String difyConversationId, String userId,
      String firstMessage, List<MessageEntity> cacheMessags) {
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

            await _difyChatRepository
                .updateConversationInCache(_currentConversation!);
            LoggerService.debug('Conversa salva no cache com sucesso',
                name: 'ChatPresenter');
            // await _difyChatRepository.addMessagesToCache(
            //     difyConversationId, _cachedMessages);
            _conversationController.sink.add(_currentConversation);
            _messagesController.sink.add(List.from(_cachedMessages));

            await _difyChatRepository.debugCacheContents();

            LoggerService.debug(
                '------------------------------ Título do Dify carregado: "$title"',
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
      LoggerService.debug(
          'Limpando cache para conversa: ${_currentConversation!.id}',
          name: 'ChatPresenter');
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

    LoggerService.debug('isAnonymousSession: $_isAnonymousSession',
        name: 'ChatPresenter');
    LoggerService.debug('anonymousSessionId: $_anonymousSessionId',
        name: 'ChatPresenter');
    LoggerService.debug('Conversa atual limpa', name: 'ChatPresenter');
  }

  String _generateFallbackTitle(String firstMessage) {
    return firstMessage.length > 45
        ? '${firstMessage.substring(0, 45)}...'
        : firstMessage;
  }

  void dispose() {
    _difyStreamSubscription?.cancel();
    _messagesController.close();
    _conversationController.close();
    _typingTextController.close();
    _isThinkingController.close();
  }
}
