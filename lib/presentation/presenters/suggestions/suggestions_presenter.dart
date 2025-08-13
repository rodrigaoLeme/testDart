import '../../../domain/entities/suggestions/suggestion_entity.dart';

abstract class SuggestionsPresenter {
  Stream<List<SuggestionEntity>> get suggestionsStream;
  List<SuggestionEntity> get suggestions;

  Future<void> loadSuggestions();
  Future<void> refreshSuggestions();
  List<SuggestionEntity> getRandomSuggestions({int count = 4});
  void dispose();
}
