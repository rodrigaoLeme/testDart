import 'dart:async';

import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/usecases.dart';
import '../../../main/services/logger_service.dart';
import '../suggestions/suggestions_presenter.dart';
import './home_presenter.dart';

class StreamHomePresenter implements HomePresenter {
  final LoadCurrentUser _loadCurrentUserUseCase;
  final SuggestionsPresenter _suggestionsPresenter;
  final LoadConversations _loadConversations;

  StreamHomePresenter({
    required LoadCurrentUser loadCurrentUserUseCase,
    required SuggestionsPresenter suggestionsPresenter,
    required LoadConversations loadConversations,
  })  : _loadCurrentUserUseCase = loadCurrentUserUseCase,
        _suggestionsPresenter = suggestionsPresenter,
        _loadConversations = loadConversations;

  final StreamController<UserEntity?> _currentUserController =
      StreamController<UserEntity?>.broadcast();

  final StreamController<List<ConversationEntity>> _conversationsController =
      StreamController<List<ConversationEntity>>.broadcast();

  UserEntity? _currentUser;

  // Cache local
  List<ConversationEntity> _cachedConversations = [];
  Timer? _syncTimer;

  // Streams
  @override
  Stream<UserEntity?> get currentUserStream => _currentUserController.stream;

  @override
  Stream<List<SuggestionEntity>> get suggestionsStream =>
      _suggestionsPresenter.suggestionsStream;

  @override
  Stream<List<ConversationEntity>> get conversationsStream =>
      _conversationsController.stream;

  // Getters
  @override
  List<SuggestionEntity> get suggestions => _suggestionsPresenter.suggestions;

  @override
  List<ConversationEntity> get conversations => _cachedConversations;

  @override
  Future<void> loadCurrentUser() async {
    try {
      final user = await _loadCurrentUserUseCase.load();

      // Guarda referência do usuário anterior
      final previousUser = _currentUser;
      _currentUser = user;

      _currentUserController.sink.add(user);

      // CENÁRIO 1: Usuário fez login (não tinha usuário, agora tem)
      if (previousUser == null && user != null) {
        LoggerService.debug(
          'Usuário logou: ${user.id} - Carregando conversas...',
          name: 'HomePresenter',
        );
        await loadConversations();
      }

      // CENÁRIO 2: Usuário fez logout (tinha usuário, agora não tem)
      if (previousUser != null && user == null) {
        LoggerService.debug(
          'Usuário deslogou - Limpando conversas...',
          name: 'HomePresenter',
        );
        _clearConversations();
      }

      // CENÁRIO 3: Usuário já estava logado (refresh)
      if (previousUser != null && user != null && previousUser.id == user.id) {
        LoggerService.debug(
          'Refresh do usuário atual - Mantendo conversas',
          name: 'HomePresenter',
        );
        // Não precisa recarregar conversas
      }

      // CENÁRIO 4: Mudou de usuário (logout + login diferente)
      if (previousUser != null && user != null && previousUser.id != user.id) {
        LoggerService.debug(
          'Mudança de usuário: ${previousUser.id} -> ${user.id}',
          name: 'HomePresenter',
        );
        _clearConversations();
        await loadConversations();
      }
    } catch (error) {
      LoggerService.error(
        'Erro ao carregar usuário: $error',
        name: 'HomePresenter',
      );
      _currentUser = null;
      _currentUserController.sink.add(null);
      _clearConversations();
    }
  }

  @override
  Future<void> loadSuggestions() async {
    await _suggestionsPresenter.loadSuggestions();
  }

  @override
  List<SuggestionEntity> getRandomSuggestions() {
    return _suggestionsPresenter.getRandomSuggestions();
  }

  @override
  Future<void> loadConversations() async {
    try {
      // Verifica se tem usuário antes de carregar
      if (_currentUser == null) {
        LoggerService.debug(
          'Sem usuário logado - não carrega conversas',
          name: 'HomePresenter',
        );
        _clearConversations();
        return;
      }

      LoggerService.debug(
        'Carregando conversas para usuário: ${_currentUser!.id}',
        name: 'HomePresenter',
      );

      // cache primeiro
      final conversations = await _loadConversations.load(limit: 50);

      if (conversations.isNotEmpty) {
        _cachedConversations = conversations;
        _conversationsController.sink.add(conversations);

        LoggerService.debug(
          'HomePresenter: ${conversations.length} conversas carregadas',
          name: 'HomePresenter',
        );
      } else {
        // Se não tem conversas, limpa o stream
        _cachedConversations = [];
        _conversationsController.sink.add([]);

        LoggerService.debug(
          'HomePresenter: Nenhuma conversa encontrada',
          name: 'HomePresenter',
        );
      }

      // Inicia timer de sincronização periódica (opcional)
      _startPeriodicSync();
    } catch (error) {
      LoggerService.error(
        'HomePresenter: Erro ao carregar conversas: $error',
        name: 'HomePresenter',
      );

      // Em caso de erro, mantém cache atual ou lista vazia
      _conversationsController.sink.add(_cachedConversations);
    }
  }

  // Pull to refresh conversas
  @override
  Future<void> refreshConversations() async {
    try {
      LoggerService.debug(
        'HomePresenter: Forçando refresh de conversas...',
        name: 'HomePresenter',
      );

      // Força nova busca do Firebase
      final conversations = await _loadConversations.load(limit: 50);

      _cachedConversations = conversations;
      _conversationsController.sink.add(conversations);

      LoggerService.debug(
        'HomePresenter: Refresh concluído - ${conversations.length} conversas',
        name: 'HomePresenter',
      );
    } catch (error) {
      LoggerService.error(
        'HomePresenter: Erro no refresh: $error',
        name: 'HomePresenter',
      );
    }
  }

  // quando criar nova conversa
  @override
  void addNewConversation(ConversationEntity conversation) {
    LoggerService.debug(
      'HomePresenter: Adicionando nova conversa ao histórico',
      name: 'HomePresenter',
    );

    // Adiciona no início da lista
    _cachedConversations.insert(0, conversation);
    _conversationsController.sink.add(List.from(_cachedConversations));
  }

  // Limpa conversas (usado no logout)
  void _clearConversations() {
    LoggerService.debug(
      'Limpando histórico de conversas',
      name: 'HomePresenter',
    );

    _cachedConversations = [];
    _conversationsController.sink.add([]);
    _syncTimer?.cancel();
  }

  // quando atualizar uma conversa
  @override
  void updateConversation(ConversationEntity conversation) {
    LoggerService.debug(
      'HomePresenter: Atualizando conversa no histórico',
      name: 'HomePresenter',
    );

    final index =
        _cachedConversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      // Remove a conversa antiga
      _cachedConversations.removeAt(index);
      // Adiciona a atualizada no início
      _cachedConversations.insert(0, conversation);
      _conversationsController.sink.add(List.from(_cachedConversations));
    }
  }

  // delata conversa
  @override
  void deleteConversation(String conversationId) {
    LoggerService.debug(
      'HomePresenter: Removendo conversa do histórico',
      name: 'HomePresenter',
    );

    _cachedConversations.removeWhere((c) => c.id == conversationId);
    _conversationsController.sink.add(List.from(_cachedConversations));
  }

  // Sync periódico a cada 5 minutos
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _syncInBackground();
    });
  }

  void _syncInBackground() {
    // Sincroniza em background sem bloquear UI
    _loadConversations.load(limit: 50).then((conversations) {
      if (_hasChanges(conversations)) {
        _cachedConversations = conversations;
        _conversationsController.sink.add(conversations);

        LoggerService.debug(
          'HomePresenter: Sync em background - ${conversations.length} conversas',
          name: 'HomePresenter',
        );
      }
    }).catchError((error) {
      LoggerService.debug(
        'HomePresenter: Erro no sync em background: $error',
        name: 'HomePresenter',
      );
    });
  }

  bool _hasChanges(List<ConversationEntity> newConversations) {
    if (_cachedConversations.length != newConversations.length) return true;

    for (int i = 0; i < _cachedConversations.length; i++) {
      if (_cachedConversations[i].id != newConversations[i].id ||
          _cachedConversations[i].updatedAt != newConversations[i].updatedAt) {
        return true;
      }
    }

    return false;
  }

  // chamado após login bem-sucedido
  Future<void> onUserLogin() async {
    LoggerService.debug(
      'onUserLogin chamado - recarregando dados do usuário',
      name: 'HomePresenter',
    );

    // Recarrega usuário e conversas
    await loadCurrentUser();
    // loadConversations será chamado automaticamente se usuário foi carregado
  }

  // chamado após logout
  void onUserLogout() {
    LoggerService.debug(
      'onUserLogout chamado - limpando dados',
      name: 'HomePresenter',
    );

    _currentUser = null;
    _currentUserController.sink.add(null);
    _clearConversations();
  }

  void dispose() {
    _syncTimer?.cancel();
    _currentUserController.close();
    _suggestionsPresenter.dispose();
    _conversationsController.close();
  }
}
