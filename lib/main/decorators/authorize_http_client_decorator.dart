import 'dart:io';

import '../../data/http/http.dart';
import '../../main/flavors.dart';

class AuthorizeHttpClientDecorator implements HttpClient {
  final HttpClient decoratee;

  AuthorizeHttpClientDecorator({
    required this.decoratee,
  });

  @override
  Future<dynamic> request({
    required String url,
    required HttpMethod method,
    Map? body,
    Map? headers,
    Map<String, dynamic>? queryParameters,
    File? file,
  }) async {
    final authorizedHeaders = <String, String>{};

    // Adiciona headers existentes
    if (headers != null) {
      authorizedHeaders.addAll(headers.cast<String, String>());
    }

    // ✅ CORREÇÃO: Não sobrescrever se já existe Authorization
    if (!authorizedHeaders.containsKey('Authorization')) {
      authorizedHeaders['Authorization'] = 'Bearer ${Flavor.difyApiKey}';
    }
    Uri uri = Uri.parse(url);
    final finalUri = uri.replace(queryParameters: queryParameters);
    return await decoratee.request(
      url: finalUri.toString(),
      method: method,
      body: body,
      headers: authorizedHeaders,
      file: file,
    );
  }
}
