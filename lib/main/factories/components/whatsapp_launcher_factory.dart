import 'dart:ui';

import '../../../ui/components/whatsapp_settings_tile.dart';
import '../../../ui/helpers/helpers.dart';

class WhatsAppConfig {
  static const String supportPhone = '5512982000062';
  static const String supportMessage = '';
  static String get supportTitle => R.string.hopeBot;
  static const String supportIcon = 'esperanca.png';
}

WhatsAppSettingsTile makeSupportWhatsAppTile({
  VoidCallback? onSuccess,
  VoidCallback? onError,
}) {
  return WhatsAppSettingsTile(
    phoneNumber: WhatsAppConfig.supportPhone,
    message: WhatsAppConfig.supportMessage,
    title: WhatsAppConfig.supportTitle,
    icon: WhatsAppConfig.supportIcon,
    onSuccess: onSuccess,
    onError: onError,
  );
}
