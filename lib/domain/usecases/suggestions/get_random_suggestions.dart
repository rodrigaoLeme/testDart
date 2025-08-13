import '../../entities/suggestions/suggestion_entity.dart';

abstract class GetRandomSuggestions {
  List<SuggestionEntity> getRandomSuggestions(
    List<SuggestionEntity> allSuggestions, {
    int count = 4,
  });
}
