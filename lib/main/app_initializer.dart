import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'factories/usecases/language/language.dart';
import 'services/language_service.dart';

class AppInitializer {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Configuração de orientação
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Inicializa Firebase
    await Firebase.initializeApp();

    // Inicializa o serviço de idiomas
    LanguageService.instance.initialize(
      loadCurrentLanguage: makeLocalLoadCurrentLanguage(),
      saveCurrentLanguage: makeLocalSaveCurrentLanguage(),
    );

    // Carrega o idioma inicial
    await LanguageService.instance.loadInitialLanguage();
  }
}
