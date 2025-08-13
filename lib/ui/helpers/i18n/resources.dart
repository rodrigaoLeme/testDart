import 'package:flutter/widgets.dart';

import './strings/strings.dart';

class R {
  static Translation string = PtBr();

  static void load(Locale locale) {
    switch (locale.toString()) {
      case 'pt_BR':
        string = PtBr();
        break;
      case 'es':
        string = Es();
        break;
      default:
        string = Us();
        break;
    }
  }
}
