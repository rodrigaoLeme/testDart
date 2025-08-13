import '../../../../presentation/presenters/suggestions/stream_suggestions_presenter.dart';
import '../../../../presentation/presenters/suggestions/suggestions_presenter.dart';
import '../../usecases/suggestions/suggestions.dart';

SuggestionsPresenter makeSuggestionsPresenter() => StreamSuggestionsPresenter(
      loadSuggestions: makeLoadSuggestions(),
      syncSuggestions: makeSyncSuggestions(),
      getRandomSuggestions: makeGetRandomSuggestions(),
    );
