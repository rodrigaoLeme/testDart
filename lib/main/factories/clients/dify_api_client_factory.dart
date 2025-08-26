import '../../../data/clients/dify_api_client.dart';
import '../../../main/flavors.dart';
import '../http/authorize_http_client_decorator_factory.dart';

DifyApiClient makeDifyApiClient() => DifyApiClient(
      baseUrl: Flavor.difyBaseUrl,
      apiKey: Flavor.difyApiKey,
      httpClient: makeAuthorizeHttpClientDecorator(),
    );
