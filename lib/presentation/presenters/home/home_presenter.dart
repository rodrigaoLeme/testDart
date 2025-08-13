import '../../../domain/entities/entities.dart';

abstract class HomePresenter {
  Stream<UserEntity?> get currentUserStream;
  Stream<List<SuggestionEntity>> get suggestionsStream;
  List<SuggestionEntity> get suggestions;

  Future<void> loadCurrentUser();
  Future<void> loadSuggestions();
  List<SuggestionEntity> getRandomSuggestions();
}
