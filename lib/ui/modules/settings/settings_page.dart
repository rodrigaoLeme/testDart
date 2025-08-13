import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../domain/entities/entities.dart';
import '../../../presentation/presenters/settings/settings_presenter.dart';
import '../../../share/utils/app_colors.dart';
import '../../components/components.dart';
import '../../helpers/helpers.dart';
import '../../mixins/mixins.dart';

class SettingsPage extends StatefulWidget {
  final SettingsPresenter presenter;

  const SettingsPage({super.key, required this.presenter});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with LoadingManager, NavigationManager, UIErrorManager {
  late StreamSubscription _languageSubscription;

  @override
  void initState() {
    super.initState();
    widget.presenter.loadCurrentUser();

    _languageSubscription = widget.presenter.currentLanguageStream.listen(
      (languageEntity) {
        if (mounted) {
          setState(() {});
        }
      },
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        widget.presenter.loadLanguages();
      }
    });
  }

  @override
  void dispose() {
    _languageSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    handleLoading(context, widget.presenter.isLoadingStream);
    handleNavigation(widget.presenter.navigateToStream);
    handleMainError(context, widget.presenter.mainErrorStream);

    return Scaffold(
      backgroundColor: AppColors.blue,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.darkBlue,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          widget.presenter.goBack();
        },
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 24,
        ),
      ),
      title: Text(
        R.string.settings,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildBody() {
    return StreamBuilder<UserEntity?>(
      stream: widget.presenter.currentUserStream,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;

        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    UserProfileHeader(user: user),
                    const SizedBox(height: 32),
                    _buildLanguageOption(),
                    const SizedBox(height: 16),
                    _buildProviderOption(user),
                    const SizedBox(height: 16),
                    _buildFAQOption(),
                    const SizedBox(height: 16),
                    _buildItemOption(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildLogoutButton(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption() {
    return StreamBuilder<LanguageEntity>(
      stream: widget.presenter.currentLanguageStream,
      builder: (context, snapshot) {
        final currentLanguage =
            snapshot.data ?? widget.presenter.currentLanguage;

        if (currentLanguage == null) {
          return SettingsOptionTile(
            icon: 'globe.png',
            title: R.string.language,
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.chevron_right,
                    color: AppColors.textPrimary, size: 20),
              ],
            ),
            onTap: _showLanguageModal,
          );
        }

        return SettingsOptionTile(
          icon: 'globe.png',
          title: R.string.language,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                currentLanguage.flag,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 8),
              Text(
                currentLanguage.name,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  color: AppColors.textPrimary, size: 20),
            ],
          ),
          onTap: _showLanguageModal,
        );
      },
    );
  }

  Widget _buildProviderOption(UserEntity user) {
    return SettingsOptionTile(
      icon: "seal.png",
      title: R.string.provider,
      titleColor: AppColors.textSecondary,
      trailing: Text(
        user.providerDisplayName,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
      onTap: null,
    );
  }

  Widget _buildFAQOption() {
    return SettingsOptionTile(
      icon: 'faq.png',
      title: R.string.faq.toUpperCase(),
      onTap: () {
        Modular.to.pushNamed('/faq');
      },
    );
  }

  Widget _buildItemOption() {
    return SettingsOptionTile(
      icon: 'info-circle.png',
      title: 'Item',
      onTap: () {},
    );
  }

  Widget _buildLogoutButton() {
    return SettingsOptionTile(
      icon: 'logout.png',
      title: R.string.logout,
      onTap: _showLogoutDialog,
    );
  }

  void _showLanguageModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => LanguageModal(presenter: widget.presenter),
    );
  }

  void _showLogoutDialog() {
    ConfirmationDialog.show(
      context: context,
      title: R.string.logout,
      message: R.string.sureLogout,
      confirmText: R.string.logoutBtn,
      cancelText: R.string.cancel,
      onConfirm: () => widget.presenter.logout(),
    );
  }
}
