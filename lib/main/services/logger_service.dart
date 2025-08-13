import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../flavors.dart';

class LoggerService {
  LoggerService._();
  static final LoggerService _instance = LoggerService._();
  static LoggerService get instance => _instance;

  // Só loga em debug/development
  static bool get _shouldLog {
    return kDebugMode || Flavor.isDevelopment();
  }

  // Log de debug (removido em produção)
  static void debug(String message,
      {String? name, Object? error, StackTrace? stackTrace}) {
    if (_shouldLog) {
      developer.log(message,
          name: name ?? 'Debug', error: error, stackTrace: stackTrace);
    }
  }

  // Log de info (mantido em produção, mas sem dados sensíveis)
  static void info(String message, {String? name}) {
    developer.log(message, name: name ?? 'Info');
  }

  // Log de erro (sempre mantido para monitoramento)
  static void error(String message,
      {String? name, Object? error, StackTrace? stackTrace}) {
    developer.log(message,
        name: name ?? 'Error', error: error, stackTrace: stackTrace);

    // Em produção, pode enviar para Firebase Crashlytics
    if (!kDebugMode) {
      // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
    }
  }

  // Log de analytics/métricas (sempre ativo)
  static void analytics(String event, Map<String, Object?> map,
      {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      developer.log('Analytics: $event - $parameters', name: 'Analytics');
    }
    // Em produção, enviar para Firebase Analytics
    // FirebaseAnalytics.instance.logEvent(name: event, parameters: parameters);
  }
}
