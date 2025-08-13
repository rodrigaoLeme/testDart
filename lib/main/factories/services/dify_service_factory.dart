import '../../../data/services/dify_service.dart';
import '../../../main/flavors.dart';
import '../http/authorize_http_client_decorator_factory.dart';

DifyService makeDifyService() => DifyService(
      httpClient: makeAuthorizeHttpClientDecorator(),
      apiKey: Flavor.difyApiKey,
      baseUrl: Flavor.difyBaseUrl,
    );
