import 'dart:ui';

import '../../domain/usecases/language/language.dart';

class DeviceLanguageAdapter implements GetDeviceLanguage {
  @override
  String get deviceLanguageCode {
    final locale = PlatformDispatcher.instance.locale;

    switch (locale.languageCode) {
      case 'pt':
        return 'pt_BR';
      case 'es':
        return 'es';
      case 'en':
      default:
        return 'en';
    }
  }
}
