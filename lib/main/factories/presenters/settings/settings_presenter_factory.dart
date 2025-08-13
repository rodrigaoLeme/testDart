import '../../../../../presentation/presenters/settings/settings_presenter.dart';
import '../../../../../presentation/presenters/settings/stream_settings_presenter.dart';
import '../../usecases/account/account.dart';
import '../../usecases/user/user.dart';

SettingsPresenter makeSettingsPresenter() => StreamSettingsPresenter(
      loadCurrentUser: makeFirebaseLoadCurrentUser(),
      deleteCurrentAccount: makeFirebaseDeleteCurrentAccount(),
    );
