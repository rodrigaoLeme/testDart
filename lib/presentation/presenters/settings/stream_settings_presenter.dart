import 'dart:async';

import '../../../domain/entities/entities.dart';
import '../../../domain/helpers/helpers.dart';
import '../../../domain/usecases/usecases.dart';
import '../../../main/helpers/dify_cache_helper.dart';
import '../../../main/routes_app.dart';
import '../../../main/services/language_service.dart';
import '../../../ui/helpers/helpers.dart';
import '../../../ui/mixins/navigation_data.dart';
import '../../mixins/mixins.dart';
import './settings_presenter.dart';

class StreamSettingsPresenter
    with LoadingManager, NavigationManager, UIErrorManager
    implements SettingsPresenter {
  final LoadCurrentUser _loadCurrentUser;
  final DeleteCurrentAccount _deleteCurrentAccount;

  StreamSettingsPresenter({
    required LoadCurrentUser loadCurrentUser,
    required DeleteCurrentAccount deleteCurrentAccount,
  })  : _loadCurrentUser = loadCurrentUser,
        _deleteCurrentAccount = deleteCurrentAccount {
    // Agenda a inicialização para o próximo frame
    Future.microtask(() => _initializeCurrentLanguage());
  }

  void _initializeCurrentLanguage() {
    try {
      final currentLanguageCode = LanguageService.instance.currentLanguageCode;

      if (currentLanguageCode.isEmpty) {
        final englishLanguage = _buildLanguageEntityFromCode('en');
        _currentLanguageController.sink.add(englishLanguage);

        _availableLanguagesController.sink.add([
          _buildLanguageEntityFromCode('en'),
          _buildLanguageEntityFromCode('pt_BR'),
          _buildLanguageEntityFromCode('es'),
        ]);
        return;
      }

      final defaultLanguage = _buildLanguageEntityFromCode(currentLanguageCode);

      _lastCurrentLanguage = defaultLanguage;
      _currentLanguageController.sink.add(defaultLanguage);

      final languages = [
        _buildLanguageEntityFromCode('en',
            isSelected: currentLanguageCode == 'en'),
        _buildLanguageEntityFromCode('pt_BR',
            isSelected: currentLanguageCode == 'pt_BR'),
        _buildLanguageEntityFromCode('es',
            isSelected: currentLanguageCode == 'es'),
      ];
      _lastAvailableLanguages = languages;
      _availableLanguagesController.sink.add(languages);
    } catch (error) {
      final englishLanguage = _buildLanguageEntityFromCode('en');
      _currentLanguageController.sink.add(englishLanguage);

      _availableLanguagesController.sink.add([
        englishLanguage,
        _buildLanguageEntityFromCode('pt_BR'),
        _buildLanguageEntityFromCode('es'),
      ]);
    }
  }

  LanguageEntity _buildLanguageEntityFromCode(String code,
      {bool isSelected = true}) {
    switch (code) {
      case 'pt_BR':
        return LanguageEntity(
          code: 'pt_BR',
          name: 'Português',
          flag: 'lib/ui/assets/images/countries/br.png',
          isSelected: isSelected,
        );
      case 'es':
        return LanguageEntity(
          code: 'es',
          name: 'Español',
          flag: 'lib/ui/assets/images/countries/es.png',
          isSelected: isSelected,
        );
      default:
        return LanguageEntity(
          code: 'en',
          name: 'English',
          flag: 'lib/ui/assets/images/countries/en.png',
          isSelected: isSelected,
        );
    }
  }

  final StreamController<UserEntity?> _currentUserController =
      StreamController<UserEntity?>.broadcast();

  final StreamController<LanguageEntity> _currentLanguageController =
      StreamController<LanguageEntity>.broadcast();

  final StreamController<List<LanguageEntity>> _availableLanguagesController =
      StreamController<List<LanguageEntity>>.broadcast();

  LanguageEntity? _lastCurrentLanguage;
  List<LanguageEntity>? _lastAvailableLanguages;

  @override
  Stream<UserEntity?> get currentUserStream => _currentUserController.stream;

  @override
  Stream<LanguageEntity> get currentLanguageStream =>
      _currentLanguageController.stream;

  @override
  Stream<List<LanguageEntity>> get availableLanguagesStream =>
      _availableLanguagesController.stream;

  @override
  LanguageEntity? get currentLanguage => _lastCurrentLanguage;

  @override
  List<LanguageEntity> get availableLanguages => _lastAvailableLanguages ?? [];

  @override
  Future<void> loadCurrentUser() async {
    try {
      final user = await _loadCurrentUser.load();
      _currentUserController.sink.add(user);
    } catch (error) {
      _currentUserController.sink.add(null);
      if (error is DomainError) {
        _handleError(error);
      } else {
        mainError = UIError.unexpected;
      }
    }
  }

  @override
  Future<void> loadLanguages() async {
    try {
      final currentLanguageCode = LanguageService.instance.currentLanguageCode;

      if (currentLanguageCode.isEmpty) {
        _initializeCurrentLanguage();
        return;
      }

      final languages = [
        LanguageEntity(
          code: 'en',
          name: R.string.english,
          flag: 'lib/ui/assets/images/countries/en.png',
          isSelected: currentLanguageCode == 'en',
        ),
        LanguageEntity(
          code: 'pt_BR',
          name: R.string.portuguese,
          flag: 'lib/ui/assets/images/countries/br.png',
          isSelected: currentLanguageCode == 'pt_BR',
        ),
        LanguageEntity(
          code: 'es',
          name: R.string.spanish,
          flag: 'lib/ui/assets/images/countries/es.png',
          isSelected: currentLanguageCode == 'es',
        ),
      ];

      _lastAvailableLanguages = languages;
      _availableLanguagesController.sink.add(languages);

      final currentLanguage = languages.firstWhere(
        (lang) => lang.isSelected,
        orElse: () => languages.first,
      );

      _lastCurrentLanguage = currentLanguage;
      _currentLanguageController.sink.add(currentLanguage);
    } catch (error) {
      if (error is DomainError) {
        _handleError(error);
      } else {
        mainError = UIError.unexpected;
      }
    }
  }

  @override
  Future<void> changeLanguage(String languageCode) async {
    try {
      isLoading = LoadingData(isLoading: true);

      await LanguageService.instance.changeLanguage(languageCode);

      await loadLanguages();

      isLoading = LoadingData(isLoading: false);
      _triggerUIRebuild();
    } catch (error) {
      isLoading = LoadingData(isLoading: false);
      if (error is DomainError) {
        _handleError(error);
      } else {
        mainError = UIError.unexpected;
      }
    }
  }

  void _triggerUIRebuild() {
    if (_lastCurrentLanguage != null) {
      _currentLanguageController.sink.add(_lastCurrentLanguage!);
    }
  }

  @override
  Future<void> logout() async {
    try {
      isLoading = LoadingData(isLoading: true);

      await _deleteCurrentAccount.delete();
      // Limpar tudo (logout)
      DifyCacheHelper.clearAll();

      isLoading = LoadingData(isLoading: false);
      navigateTo = NavigationData(route: Routes.splash, clear: true);
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
  Future<void> goBack() async {
    navigateTo = NavigationData(route: Routes.home, clear: true);
  }

  void _handleError(DomainError error) {
    switch (error) {
      case DomainError.accessDenied:
        mainError = UIError.invalidCredentials;
        break;
      case DomainError.networkError:
        mainError = UIError.networkError;
        break;
      default:
        mainError = UIError.unexpected;
    }
  }

  void dispose() {
    _currentUserController.close();
    _currentLanguageController.close();
    _availableLanguagesController.close();
  }
}
