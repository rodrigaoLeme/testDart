import 'package:flutter/material.dart';

import '../../../domain/entities/login/login_provider.dart';
import '../../../presentation/presenters/login/login_presenter.dart';
import '../../../share/ds/ds_social_login_button.dart';
import '../../../share/utils/app_colors.dart';
import '../../helpers/helpers.dart';
import '../../mixins/mixins.dart';
import './login_presenter.dart';

class LoginPage extends StatefulWidget {
  final LoginPresenter presenter;

  const LoginPage({super.key, required this.presenter});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with LoadingManager, NavigationManager, UIErrorManager {
  void Function() _getProviderAction(LoginProvider provider) {
    switch (provider) {
      case LoginProvider.google:
        return widget.presenter.signInWithGoogle;
      case LoginProvider.apple:
        return widget.presenter.signInWithApple;
      case LoginProvider.facebook:
        return widget.presenter.signInWithFacebook;
      case LoginProvider.microsoft:
        return widget.presenter.signInWithMicrosoft;
    }
  }

  List<Widget> _buildLoginButtons() {
    return LoginProviderExtension.availableProviders
        .map((provider) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SocialLoginButton(
                iconAsset: provider.iconAsset,
                text: provider.getDisplayText(),
                onPressed: _getProviderAction(provider),
              ),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    handleLoading(context, widget.presenter.isLoadingStream);
    handleNavigation(widget.presenter.navigateToStream);
    handleMainError(context, widget.presenter.mainErrorStream);

    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 70),
              // Logo
              Container(
                width: 200,
                height: 170,
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.darkBlue,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'lib/ui/assets/images/logo/logo7chat.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),

              const Spacer(),

              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 80),
                child: Column(
                  children: [
                    const Text(
                      '7Chat.ai',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      R.string.sloganApp,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 80),
                    ..._buildLoginButtons(),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
