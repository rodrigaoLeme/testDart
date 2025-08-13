import '../../../domain/entities/entities.dart';
import '../../../ui/helpers/helpers.dart';
import '../../../ui/mixins/navigation_data.dart';
import '../../mixins/mixins.dart';

abstract class SettingsPresenter {
  Stream<UserEntity?> get currentUserStream;
  Stream<LanguageEntity> get currentLanguageStream;
  Stream<List<LanguageEntity>> get availableLanguagesStream;
  Stream<NavigationData?> get navigateToStream;
  Stream<UIError?> get mainErrorStream;
  Stream<LoadingData> get isLoadingStream;

  LanguageEntity? get currentLanguage;
  List<LanguageEntity> get availableLanguages;

  Future<void> loadCurrentUser();
  Future<void> loadLanguages();
  Future<void> changeLanguage(String languageCode);
  Future<void> logout();
  Future<void> goBack();
}
