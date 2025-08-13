import '../../../../../presentation/presenters/login/stream_login_presenter.dart';
import '../../../../../ui/modules/login/login_presenter.dart';
import '../../firebase/firebase_authentication_adapter_factory.dart';

LoginPresenter makeLoginPresenter() => StreamLoginPresenter(
      authentication: makeFirebaseAuthenticationAdapter(),
    );
