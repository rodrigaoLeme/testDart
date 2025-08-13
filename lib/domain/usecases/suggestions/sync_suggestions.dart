import '../../entities/suggestions/suggestion_entity.dart';

abstract class SyncSuggestions {
  Future<List<SuggestionEntity>> sync({bool forceRefresh = false});
}
