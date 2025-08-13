import 'dart:async';

import '../../../domain/entities/entities.dart';
import '../../../domain/helpers/helpers.dart';
import '../../../domain/usecases/faq/faq.dart';
import '../../../main/routes_app.dart';
import '../../../ui/helpers/helpers.dart';
import '../../../ui/mixins/navigation_data.dart';
import '../../mixins/mixins.dart';
import './faq_presenter.dart';

class StreamFAQPresenter
    with LoadingManager, NavigationManager, UIErrorManager
    implements FAQPresenter {
  final LoadFAQItems _loadFAQItems;
  final SyncFAQItems _syncFAQItems;

  StreamFAQPresenter({
    required LoadFAQItems loadFAQItems,
    required SyncFAQItems syncFAQItems,
  })  : _loadFAQItems = loadFAQItems,
        _syncFAQItems = syncFAQItems;

  final StreamController<List<FAQItemEntity>> _faqItemsController =
      StreamController<List<FAQItemEntity>>.broadcast();

  final StreamController<String> _searchQueryController =
      StreamController<String>.broadcast();

  // Cache para valores síncronos
  List<FAQItemEntity> _cachedFAQItems = [];
  List<FAQItemEntity> _originalFAQItems = [];
  String _cachedSearchQuery = '';

  @override
  Stream<List<FAQItemEntity>> get faqItemsStream => _faqItemsController.stream;

  @override
  Stream<String> get searchQueryStream => _searchQueryController.stream;

  @override
  List<FAQItemEntity> get faqItems => _cachedFAQItems;

  @override
  String get searchQuery => _cachedSearchQuery;

  @override
  Future<void> loadFAQ() async {
    try {
      final items = await _loadFAQItems.load();

      _originalFAQItems = items;
      _cachedFAQItems = items;
      _faqItemsController.sink.add(items);

      // Em background, tenta sincronizar
      _backgroundSync();
    } catch (error) {
      if (error is DomainError) {
        _handleError(error);
      } else {
        mainError = UIError.unexpected;
      }
    }
  }

  @override
  Future<void> refreshFAQ() async {
    try {
      isLoading = LoadingData(isLoading: true);

      final items = await _syncFAQItems.sync(forceRefresh: true);

      _originalFAQItems = items;
      _cachedFAQItems = items;
      _faqItemsController.sink.add(items);

      if (_cachedSearchQuery.isNotEmpty) {
        searchFAQ(_cachedSearchQuery);
      }

      isLoading = LoadingData(isLoading: false);
    } catch (error) {
      isLoading = LoadingData(isLoading: false);
      if (error is DomainError) {
        _handleError(error);
      } else {
        mainError = UIError.unexpected;
      }
    }
  }

  @override
  void searchFAQ(String query) {
    _cachedSearchQuery = query;
    _searchQueryController.sink.add(query);

    if (query.isEmpty) {
      // Se busca vazia, mostra todos os items
      _cachedFAQItems = _originalFAQItems;
      _faqItemsController.sink.add(_originalFAQItems);
      return;
    }

    // Filtra items baseado na query (busca em título e descrição)
    final filteredItems = _originalFAQItems.where((item) {
      final searchTerm = query.toLowerCase();
      final titleMatch = item.title.toLowerCase().contains(searchTerm);
      final descriptionMatch =
          item.description.toLowerCase().contains(searchTerm);

      return titleMatch || descriptionMatch;
    }).toList();

    _cachedFAQItems = filteredItems;
    _faqItemsController.sink.add(filteredItems);
  }

  @override
  Future<void> goBack() async {
    navigateTo = NavigationData(route: Routes.home, clear: true);
  }

  Future<void> _backgroundSync() async {
    try {
      final items = await _syncFAQItems.sync();

      // Se retornou items diferentes, atualiza a UI
      if (_hasChanges(items)) {
        _originalFAQItems = items;
        _cachedFAQItems = items;
        _faqItemsController.sink.add(items);

        // Reaplica filtro se houver busca ativa
        if (_cachedSearchQuery.isNotEmpty) {
          searchFAQ(_cachedSearchQuery);
        }
      } else {
        // FAQ atualizado
      }
    } catch (error) {
      // Em background sync, não mostra erro para o usuário
    }
  }

  bool _hasChanges(List<FAQItemEntity> newItems) {
    if (_originalFAQItems.length != newItems.length) return true;

    for (int i = 0; i < _originalFAQItems.length; i++) {
      final old = _originalFAQItems[i];
      final current = newItems[i];

      if (old.id != current.id ||
          old.title != current.title ||
          old.description != current.description) {
        return true;
      }
    }

    return false;
  }

  void _handleError(DomainError error) {
    switch (error) {
      case DomainError.networkError:
        mainError = UIError.networkError;
        break;
      case DomainError.notFound:
        mainError = UIError.notFound;
        break;
      default:
        mainError = UIError.unexpected;
    }
  }

  void dispose() {
    _faqItemsController.close();
    _searchQueryController.close();
  }
}
