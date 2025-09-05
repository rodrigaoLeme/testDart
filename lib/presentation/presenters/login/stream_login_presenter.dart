import '../../../domain/helpers/helpers.dart';
import '../../../infra/firebase/firebase_authentication_adapter.dart';
import '../../../main/routes_app.dart';
import '../../../ui/helpers/errors/ui_error.dart';
import '../../../ui/mixins/navigation_data.dart';
import '../../mixins/mixins.dart';
import './login_presenter.dart';

class StreamLoginPresenter
    with LoadingManager, NavigationManager, UIErrorManager
    implements LoginPresenter {
  final FirebaseAuthenticationAdapter authentication;

  StreamLoginPresenter({
    required this.authentication,
  });

  @override
  Future<void> signInWithGoogle() async {
    try {
      isLoading = LoadingData(isLoading: true);
      await authentication.signInWithGoogle();
      await _saveAccountAndNavigate();
    } on DomainError catch (error) {
      isLoading = LoadingData(isLoading: false);
      _handleError(error);
    }
  }

  @override
  Future<void> signInWithApple() async {
    try {
      isLoading = LoadingData(isLoading: true);
      await authentication.signInWithApple();
      await _saveAccountAndNavigate();
    } on DomainError catch (error) {
      isLoading = LoadingData(isLoading: false);
      _handleError(error);
    }
  }

  @override
  Future<void> signInWithMicrosoft() async {
    try {
      isLoading = LoadingData(isLoading: true);
      await authentication.signInWithMicrosoft();
      await _saveAccountAndNavigate();
    } on DomainError catch (error) {
      isLoading = LoadingData(isLoading: false);
      _handleError(error);
    }
  }

  @override
  Future<void> signInWithFacebook() async {
    try {
      isLoading = LoadingData(isLoading: true);
      await authentication.signInWithFacebook();
      await _saveAccountAndNavigate();
    } on DomainError catch (error) {
      isLoading = LoadingData(isLoading: false);
      _handleError(error);
    }
  }

  Future<void> _saveAccountAndNavigate() async {
    isLoading = LoadingData(isLoading: false);
    navigateTo = NavigationData(
      route: Routes.home,
      clear: true,
      arguments: {
        'shouldReloadUser': true,
        'justLoggedIn': true,
      },
    );
  }

  void _handleError(DomainError error) {
    switch (error) {
      case DomainError.invalidCredentials:
        mainError = UIError.invalidCredentials;
        break;
      case DomainError.accessDenied:
        mainError = UIError.invalidCredentials;
        break;
      case DomainError.authCancelled:
        mainError = UIError.authCancelled;
        break;
      case DomainError.authInProgress:
        mainError = UIError.authInProgress;
        break;
      case DomainError.networkError:
        mainError = UIError.networkError;
        break;
      case DomainError.configurationError:
        mainError = UIError.configurationError;
        break;
      case DomainError.accountDisabled:
        mainError = UIError.accountDisabled;
        break;
      case DomainError.tooManyRequests:
        mainError = UIError.tooManyRequests;
        break;
      case DomainError.webContextCancelled:
        mainError = UIError.webContextCancelled;
        break;
      default:
        mainError = UIError.unexpected;
    }
  }

  @override
  Future<void> goBack() async {
    navigateTo = NavigationData(route: Routes.home, clear: true);
  }
}
