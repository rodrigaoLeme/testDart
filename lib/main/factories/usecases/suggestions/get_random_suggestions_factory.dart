import '../../../../domain/usecases/suggestions/get_random_suggestions.dart';
import '../../repositories/suggestions_repository_factory.dart';

GetRandomSuggestions makeGetRandomSuggestions() => makeSuggestionsRepository();
