import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main/services/logger_service.dart';
import '../../main/services/url_launcher_service.dart';
import '../../share/utils/app_colors.dart';
import '../helpers/helpers.dart';
import 'settings_option_tile.dart';

class WhatsAppSettingsTile extends StatelessWidget {
  final String phoneNumber;
  final String? message;
  final String? title;
  final String? icon;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final bool showLoadingDialog;
  final bool showErrorDialog;

  const WhatsAppSettingsTile({
    Key? key,
    required this.phoneNumber,
    this.message,
    this.title = '',
    this.icon = '',
    this.onSuccess,
    this.onError,
    this.showLoadingDialog = true,
    this.showErrorDialog = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingsOptionTile(
      icon: icon!,
      title: title!,
      onTap: () => _openWhatsApp(context),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    try {
      HapticFeedback.lightImpact();

      if (showLoadingDialog && context.mounted) {
        _showLoadingDialog(context);
      }

      final success = await UrlLauncherService.openWhatsApp(
        phoneNumber: phoneNumber,
        message: message,
      );

      if (showLoadingDialog && context.mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        onSuccess?.call();
      } else {
        onError?.call();
        if (showErrorDialog && context.mounted) {
          _showErrorDialog(context);
        }
      }
    } catch (error) {
      LoggerService.error('Erro ao abrir WhatsApp: $error',
          name: 'WhatsAppSettingsTile');

      if (showLoadingDialog && context.mounted) {
        Navigator.of(context).pop();
      }

      onError?.call();
      if (showErrorDialog && context.mounted) {
        _showErrorDialog(context);
      }
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.redDanger,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          R.string.whatsAppNotAvailable,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(
          R.string.unableToOpenWhatsApp,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
