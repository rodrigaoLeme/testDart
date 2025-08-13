import '../../../ui/helpers/errors/ui_error.dart';
import '../../../ui/mixins/navigation_data.dart';
import '../../mixins/mixins.dart';

abstract class LoginPresenter {
  Stream<LoadingData> get isLoadingStream;
  Stream<NavigationData?> get navigateToStream;
  Stream<UIError?> get mainErrorStream;

  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signInWithMicrosoft();
  Future<void> signInWithFacebook();
}
