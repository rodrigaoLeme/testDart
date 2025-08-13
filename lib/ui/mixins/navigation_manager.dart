import 'package:flutter_modular/flutter_modular.dart';

import 'navigation_data.dart';

mixin NavigationManager {
  void handleNavigation(Stream<NavigationData?> stream) {
    stream.listen((data) {
      if (data != null && data.route.isNotEmpty) {
        if (data.clear == true) {
          Modular.to.navigate(data.route, arguments: data.arguments);
        } else {
          Modular.to.pushNamed(data.route, arguments: data.arguments);
        }
      }
    });
  }
}
