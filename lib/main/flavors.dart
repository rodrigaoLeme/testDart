enum FlavorTypes { dev, prod }

class Flavor {
  Flavor._instance();

  static late FlavorTypes flavorType;

  static String get flavorMessage {
    switch (flavorType) {
      case FlavorTypes.dev:
        return 'Dev';
      case FlavorTypes.prod:
        return 'Production';
    }
  }

  static String get difyBaseUrl {
    switch (flavorType) {
      case FlavorTypes.dev:
        return 'https://api.dify.ai/v1';
      case FlavorTypes.prod:
        return 'https://api.dify.ai/v1';
    }
  }

  static String get difyApiKey {
    switch (flavorType) {
      case FlavorTypes.dev:
        return 'app-XXX';
      case FlavorTypes.prod:
        return 'apiKeyProd';
    }
  }

  static bool get enableDebugLogs {
    switch (flavorType) {
      case FlavorTypes.dev:
        return true;
      case FlavorTypes.prod:
        return false;
    }
  }

  static bool get enableAnalytics {
    switch (flavorType) {
      case FlavorTypes.dev:
        return false;
      case FlavorTypes.prod:
        return true;
    }
  }

  static bool isProduction() => flavorType == FlavorTypes.prod;
  static bool isDevelopment() => flavorType == FlavorTypes.dev;

  @Deprecated('Use difyBaseUrl instead')
  static String get apiBaseUrl => difyBaseUrl;

  @Deprecated('Use difyApiKey instead')
  static String get apiKey => difyApiKey;
}
