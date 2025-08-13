import '../../../domain/usecases/usecases.dart';
import '../../../main/routes_app.dart';
import '../../../main/services/logger_service.dart';
import '../../../ui/mixins/navigation_data.dart';
import '../../mixins/navigation_manager.dart';
import 'splash_presenter.dart';

class StreamSplashPresenter with NavigationManager implements SplashPresenter {
  final LoadCurrentAccount loadCurrentAccount;
  final LoadFAQItems loadFAQItems;
  final LoadSuggestions loadSuggestions;

  StreamSplashPresenter({
    required this.loadCurrentAccount,
    required this.loadFAQItems,
    required this.loadSuggestions,
  });

  @override
  Future<void> checkAccount({int durationInSeconds = 3}) async {
    final List<Future> futures = [
      Future.delayed(
          Duration(seconds: durationInSeconds)), // Tempo mínimo de splash
      preloadAppData(), // Carrega dados em background
    ];

    await Future.wait(futures);
    navigateTo = NavigationData(route: Routes.home, clear: true);
  }

  @override
  Future<void> preloadAppData() async {
    try {
      LoggerService.debug('Splash: Iniciando pré-carregamento...',
          name: 'SplashPreload');

      // CARREGA FAQ E SUGGESTIONS EM PARALELO
      final futures = [
        _preloadFAQ(),
        _preloadSuggestions(),
      ];

      await Future.wait(futures);

      LoggerService.debug('Splash: Pré-carregamento concluído!',
          name: 'SplashPreload');
    } catch (error) {
      LoggerService.debug(
          'Splash: Erro no pré-carregamento (não crítico): $error',
          name: 'SplashPreload');
      // Não impede a navegação se der erro
    }
  }

  Future<void> _preloadFAQ() async {
    try {
      LoggerService.debug('Pré-carregando FAQ...', name: 'SplashPreload');
      await loadFAQItems.load();
      LoggerService.debug('FAQ pré-carregado com sucesso',
          name: 'SplashPreload');
    } catch (error) {
      LoggerService.debug('Erro ao pré-carregar FAQ: $error',
          name: 'SplashPreload');
    }
  }

  Future<void> _preloadSuggestions() async {
    try {
      LoggerService.debug('Pré-carregando Suggestions...',
          name: 'SplashPreload');
      await loadSuggestions.load();
      LoggerService.debug('Suggestions pré-carregadas com sucesso',
          name: 'SplashPreload');
    } catch (error) {
      LoggerService.debug('Erro ao pré-carregar Suggestions: $error',
          name: 'SplashPreload');
    }
  }
}
