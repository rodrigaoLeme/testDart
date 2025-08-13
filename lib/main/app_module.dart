import 'package:flutter_modular/flutter_modular.dart';

import 'factories/modules/core_module_factory.dart';

class AppModule extends Module {
  @override
  void binds(i) {}

  @override
  void routes(r) {
    r.module(
      '/',
      module: CoreModule(),
      transition: TransitionType.fadeIn,
    );
  }
}
