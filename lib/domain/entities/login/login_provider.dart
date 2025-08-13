import 'dart:io';

import '../../../ui/helpers/helpers.dart';

enum LoginProvider {
  google,
  apple,
  facebook,
  microsoft,
}

extension LoginProviderExtension on LoginProvider {
  static List<LoginProvider> get availableProviders {
    final providers = [LoginProvider.google];

    if (Platform.isIOS) {
      providers.add(LoginProvider.apple);
    }

    providers.add(LoginProvider.facebook);
    return providers;
  }

  String get i18nKey {
    switch (this) {
      case LoginProvider.google:
        return 'loginWithGoogle';
      case LoginProvider.apple:
        return 'loginWithApple';
      case LoginProvider.facebook:
        return 'loginWithFacebook';
      case LoginProvider.microsoft:
        return 'loginWithMicrosoft';
    }
  }

  String get iconAsset {
    switch (this) {
      case LoginProvider.google:
        return 'lib/ui/assets/images/social/google.png';
      case LoginProvider.apple:
        return 'lib/ui/assets/images/social/apple.png';
      case LoginProvider.facebook:
        return 'lib/ui/assets/images/social/facebook.png';
      case LoginProvider.microsoft:
        return 'lib/ui/assets/images/social/microsoft.png';
    }
  }

  String getDisplayText() {
    switch (this) {
      case LoginProvider.google:
        return R.string.loginWithGoogle;
      case LoginProvider.apple:
        return R.string.loginWithApple;
      case LoginProvider.facebook:
        return R.string.loginWithFacebook;
      case LoginProvider.microsoft:
        return R.string.loginWithMicrosoft;
    }
  }
}
