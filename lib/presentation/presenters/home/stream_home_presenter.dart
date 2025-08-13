import 'dart:async';

import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/usecases.dart';
import '../suggestions/suggestions_presenter.dart';
import './home_presenter.dart';

class StreamHomePresenter implements HomePresenter {
  final LoadCurrentUser _loadCurrentUserUseCase;
  final SuggestionsPresenter _suggestionsPresenter;

  StreamHomePresenter({
    required LoadCurrentUser loadCurrentUserUseCase,
    required SuggestionsPresenter suggestionsPresenter,
  })  : _loadCurrentUserUseCase = loadCurrentUserUseCase,
        _suggestionsPresenter = suggestionsPresenter;

  final StreamController<UserEntity?> _currentUserController =
      StreamController<UserEntity?>.broadcast();

  @override
  Stream<UserEntity?> get currentUserStream => _currentUserController.stream;

  @override
  Stream<List<SuggestionEntity>> get suggestionsStream =>
      _suggestionsPresenter.suggestionsStream;

  @override
  List<SuggestionEntity> get suggestions => _suggestionsPresenter.suggestions;

  @override
  Future<void> loadCurrentUser() async {
    try {
      final user = await _loadCurrentUserUseCase.load();
      _currentUserController.sink.add(user);
    } catch (_) {
      _currentUserController.sink.add(null);
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

  void dispose() {
    _currentUserController.close();
    _suggestionsPresenter.dispose();
  }
}
