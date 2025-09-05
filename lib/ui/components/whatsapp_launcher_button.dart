import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main/services/logger_service.dart';
import '../../main/services/url_launcher_service.dart';
import '../../share/utils/app_colors.dart';
import '../helpers/helpers.dart';

class WhatsAppLauncherButton extends StatelessWidget {
  final String phoneNumber;
  final String? message;
  final String? title;
  final String? icon;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final bool showLoadingDialog;
  final bool showErrorDialog;

  const WhatsAppLauncherButton({
    Key? key,
    required this.phoneNumber,
    this.message,
    this.title,
    this.icon,
    this.onSuccess,
    this.onError,
    this.showLoadingDialog = true,
    this.showErrorDialog = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openWhatsApp(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Image.asset(
                  'lib/ui/assets/images/icons/$icon',
                  height: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        LoggerService.debug('WhatsApp aberto com sucesso',
            name: 'WhatsAppLauncherButton');
      } else {
        onError?.call();
        if (showErrorDialog && context.mounted) {
          _showErrorDialog(context);
        }
      }
    } catch (error) {
      LoggerService.error('Erro ao abrir WhatsApp: $error',
          name: 'WhatsAppLauncherButton');

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
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.redDanger,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          R.string.whatsAppNotAvailable,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          R.string.unableToOpenWhatsApp,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
