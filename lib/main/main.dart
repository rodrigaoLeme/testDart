import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'app.dart';
import 'app_initializer.dart';
import 'app_module.dart';

Future<void> main() async {
  await AppInitializer.initialize();

  runApp(
    ModularApp(
      module: AppModule(),
      child: const App(),
    ),
  );
}
