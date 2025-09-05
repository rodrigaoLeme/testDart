import 'package:url_launcher/url_launcher.dart';

import 'logger_service.dart';

class UrlLauncherService {
  static Future<bool> openWhatsApp({
    required String phoneNumber,
    String? message,
  }) async {
    try {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      final encodedMessage =
          message != null ? Uri.encodeComponent(message) : '';

      final whatsappUrl =
          'whatsapp://send?phone=$cleanPhone${message != null ? '&text=$encodedMessage' : ''}';

      LoggerService.debug(
        'Tentando abrir WhatsApp: $whatsappUrl',
        name: 'UrlLauncherService',
      );

      final uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        LoggerService.debug('WhatsApp aberto com sucesso',
            name: 'UrlLauncherService');
        return true;
      } else {
        // se não achar o app, abre WhatsApp Web
        LoggerService.debug(
            'WhatsApp app não disponível, tentando WhatsApp Web',
            name: 'UrlLauncherService');
        return await _openWhatsAppWeb(
            phoneNumber: cleanPhone, message: message);
      }
    } catch (error) {
      LoggerService.error(
        'Erro ao abrir WhatsApp: $error',
        name: 'UrlLauncherService',
      );
      return false;
    }
  }

  // WhatsApp Web
  static Future<bool> _openWhatsAppWeb({
    required String phoneNumber,
    String? message,
  }) async {
    try {
      final encodedMessage =
          message != null ? Uri.encodeComponent(message) : '';
      final webUrl =
          'https://wa.me/$phoneNumber${message != null ? '?text=$encodedMessage' : ''}';

      final uri = Uri.parse(webUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        LoggerService.debug('WhatsApp Web aberto com sucesso',
            name: 'UrlLauncherService');
        return true;
      }
      return false;
    } catch (error) {
      LoggerService.error(
        'Erro ao abrir WhatsApp Web: $error',
        name: 'UrlLauncherService',
      );
      return false;
    }
  }
}
