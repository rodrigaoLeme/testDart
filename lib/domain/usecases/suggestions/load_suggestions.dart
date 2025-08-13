import '../../entities/suggestions/suggestion_entity.dart';

abstract class LoadSuggestions {
  Future<List<SuggestionEntity>> load();
}
