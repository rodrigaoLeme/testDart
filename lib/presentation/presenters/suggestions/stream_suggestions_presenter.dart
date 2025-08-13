import 'dart:async';

import '../../../domain/entities/suggestions/suggestion_entity.dart';
import '../../../domain/helpers/helpers.dart';
import '../../../domain/usecases/suggestions/suggestions.dart';
import '../../../main/services/language_service.dart';
import './suggestions_presenter.dart';

class StreamSuggestionsPresenter implements SuggestionsPresenter {
  final LoadSuggestions _loadSuggestions;
  final SyncSuggestions _syncSuggestions;
  final GetRandomSuggestions _getRandomSuggestions;

  StreamSuggestionsPresenter({
    required LoadSuggestions loadSuggestions,
    required SyncSuggestions syncSuggestions,
    required GetRandomSuggestions getRandomSuggestions,
  })  : _loadSuggestions = loadSuggestions,
        _syncSuggestions = syncSuggestions,
        _getRandomSuggestions = getRandomSuggestions {
    _setupLanguageListener();
  }

  final StreamController<List<SuggestionEntity>> _suggestionsController =
      StreamController<List<SuggestionEntity>>.broadcast();

  late StreamSubscription _languageSubscription;
  String _currentLanguage = '';

  // Cache para valores síncronos
  List<SuggestionEntity> _cachedSuggestions = [];
  List<SuggestionEntity> _allSuggestions = [];

  @override
  Stream<List<SuggestionEntity>> get suggestionsStream =>
      _suggestionsController.stream;

  @override
  List<SuggestionEntity> get suggestions => _cachedSuggestions;

  void _setupLanguageListener() {
    _currentLanguage = LanguageService.instance.currentLanguageCode;

    // Escuta mudanças de idioma a cada 500ms
    _languageSubscription = Stream.periodic(
      const Duration(milliseconds: 500),
      (count) => LanguageService.instance.currentLanguageCode,
    ).distinct().listen((newLanguage) {
      if (newLanguage != _currentLanguage && newLanguage.isNotEmpty) {
        _currentLanguage = newLanguage;
        _reloadSuggestionsForNewLanguage();
      }
    });
  }

  Future<void> _reloadSuggestionsForNewLanguage() async {
    try {
      // Se já tem dados cacheados, reconverte para o novo idioma
      if (_allSuggestions.isNotEmpty) {
        // Força recarregamento do cache para aplicar novo idioma
        final items = await _loadSuggestions.load();
        _allSuggestions = items;

        // Pega 4 aleatórias no novo idioma
        final randomSuggestions =
            _getRandomSuggestions.getRandomSuggestions(items);
        _cachedSuggestions = randomSuggestions;
        _suggestionsController.sink.add(randomSuggestions);
      } else {
        // Se não tem cache, carrega do zero
        await loadSuggestions();
      }
    } catch (error) {
      _useDefaultSuggestions();
    }
  }

  @override
  Future<void> loadSuggestions() async {
    try {
      final items = await _loadSuggestions.load();

      _allSuggestions = items;

      // Pega 4 aleatórias para exibir
      final randomSuggestions =
          _getRandomSuggestions.getRandomSuggestions(items);
      _cachedSuggestions = randomSuggestions;
      _suggestionsController.sink.add(randomSuggestions);

      // Em background, tenta sincronizar
      _backgroundSync();
    } catch (error) {
      if (error is DomainError) {
        // Em caso de erro, usa sugestões padrão
        _useDefaultSuggestions();
      }
    }
  }

  @override
  Future<void> refreshSuggestions() async {
    try {
      final items = await _syncSuggestions.sync(forceRefresh: true);

      _allSuggestions = items;

      // Pega 4 novas aleatórias
      final randomSuggestions =
          _getRandomSuggestions.getRandomSuggestions(items);
      _cachedSuggestions = randomSuggestions;
      _suggestionsController.sink.add(randomSuggestions);
    } catch (error) {
      if (error is DomainError) {
        _useDefaultSuggestions();
      }
    }
  }

  @override
  List<SuggestionEntity> getRandomSuggestions({int count = 4}) {
    if (_allSuggestions.isEmpty) {
      return _getDefaultSuggestions();
    }

    final randomSuggestions = _getRandomSuggestions.getRandomSuggestions(
      _allSuggestions,
      count: count,
    );

    _cachedSuggestions = randomSuggestions;
    _suggestionsController.sink.add(randomSuggestions);

    return randomSuggestions;
  }

  Future<void> _backgroundSync() async {
    try {
      final items = await _syncSuggestions.sync();

      // Se retornou items diferentes, atualiza
      if (_hasChanges(items)) {
        _allSuggestions = items;

        // Mantém a quantidade atual de sugestões, mas pega novas aleatórias
        final newRandomSuggestions = _getRandomSuggestions.getRandomSuggestions(
          items,
          count: _cachedSuggestions.length,
        );

        _cachedSuggestions = newRandomSuggestions;
        _suggestionsController.sink.add(newRandomSuggestions);
      }
    } catch (error) {
      // Em background sync, não mostra erro
    }
  }

  bool _hasChanges(List<SuggestionEntity> newItems) {
    if (_allSuggestions.length != newItems.length) return true;

    for (int i = 0; i < _allSuggestions.length; i++) {
      final old = _allSuggestions[i];
      final current = newItems[i];

      if (old.id != current.id || old.text != current.text) {
        return true;
      }
    }

    return false;
  }

  void _useDefaultSuggestions() {
    final defaultSuggestions = _getDefaultSuggestions();
    _cachedSuggestions = defaultSuggestions;
    _suggestionsController.sink.add(defaultSuggestions);
  }

  List<SuggestionEntity> _getDefaultSuggestions() {
    // hardcoded como fallback
    final currentLanguage = LanguageService.instance.currentLanguageCode;

    switch (currentLanguage) {
      case 'pt_BR':
        return [
          SuggestionEntity(
            id: 'default_1',
            order: 1,
            active: true,
            createdAt: DateTime.now(),
            text: 'Devo acreditar em Ellen White?',
          ),
          SuggestionEntity(
            id: 'default_2',
            order: 2,
            active: true,
            createdAt: DateTime.now(),
            text: 'Igreja Adventista é seita?',
          ),
          SuggestionEntity(
            id: 'default_3',
            order: 3,
            active: true,
            createdAt: DateTime.now(),
            text: 'Jesus voltará quando?',
          ),
          SuggestionEntity(
            id: 'default_4',
            order: 4,
            active: true,
            createdAt: DateTime.now(),
            text: 'O que significa o sábado?',
          ),
        ];
      case 'es':
        return [
          SuggestionEntity(
            id: 'default_1',
            order: 1,
            active: true,
            createdAt: DateTime.now(),
            text: '¿Debo creer en Ellen White?',
          ),
          SuggestionEntity(
            id: 'default_2',
            order: 2,
            active: true,
            createdAt: DateTime.now(),
            text: '¿La Iglesia Adventista es una secta?',
          ),
          SuggestionEntity(
            id: 'default_3',
            order: 3,
            active: true,
            createdAt: DateTime.now(),
            text: '¿Cuándo regresará Jesús?',
          ),
          SuggestionEntity(
            id: 'default_4',
            order: 4,
            active: true,
            createdAt: DateTime.now(),
            text: '¿Qué significa el sábado?',
          ),
        ];
      default: // English
        return [
          SuggestionEntity(
            id: 'default_1',
            order: 1,
            active: true,
            createdAt: DateTime.now(),
            text: 'Should I believe in Ellen White?',
          ),
          SuggestionEntity(
            id: 'default_2',
            order: 2,
            active: true,
            createdAt: DateTime.now(),
            text: 'Is the Adventist Church a sect?',
          ),
          SuggestionEntity(
            id: 'default_3',
            order: 3,
            active: true,
            createdAt: DateTime.now(),
            text: 'When will Jesus return?',
          ),
          SuggestionEntity(
            id: 'default_4',
            order: 4,
            active: true,
            createdAt: DateTime.now(),
            text: 'What does the Sabbath mean?',
          ),
        ];
    }
  }

  @override
  void dispose() {
    _languageSubscription.cancel();
    _suggestionsController.close();
  }
}
