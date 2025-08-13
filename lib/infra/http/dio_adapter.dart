import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';

import '../../data/http/http.dart';

class DioAdapter implements HttpClient {
  final Dio client;
  DioAdapter(
    this.client,
  );

  @override
  Future<dynamic> request({
    required String url,
    required HttpMethod method,
    Map? body,
    Map? headers,
    Map<String, dynamic>? queryParameters,
    File? file,
  }) async {
    final defaultHeaders = headers?.cast<String, String>() ?? {}
      ..addAll(method == HttpMethod.multipart
          ? {'content-type': 'multipart/form-data'}
          : {'content-type': 'application/json', 'accept': 'application/json'});
    final jsonBody = body != null ? jsonEncode(body) : null;
    developer.log(
        '=======================================================================',
        name: 'START');
    developer.log('HTTPLOG', name: 'DioAdapter');
    developer.log(url, name: 'URL');
    developer.log(jsonBody ?? '', name: 'BODY');
    developer.log(headers.toString(), name: 'HEADERS');
    developer.log(queryParameters.toString(), name: 'QUERYPARAMETERS');

    final option = Options(
        headers: defaultHeaders,
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 24));
    try {
      Uri uri = Uri.parse(url);
      final finalUri = uri.replace(queryParameters: queryParameters).toString();

      Response futureResponse;

      switch (method) {
        case HttpMethod.post:
          futureResponse =
              await client.post(finalUri, options: option, data: body);
          break;
        case HttpMethod.patch:
          futureResponse =
              await client.patch(finalUri, options: option, data: body);
          break;
        case HttpMethod.get:
          futureResponse = await client.get(finalUri, options: option);
          break;
        case HttpMethod.put:
          futureResponse =
              await client.put(finalUri, options: option, data: body);
          break;
        case HttpMethod.delete:
          futureResponse = await client.delete(finalUri, options: option);
          break;
        default:
          throw HttpError.serverError;
      }
      return _handleResponse(futureResponse);
    } catch (error) {
      developer.log(error.toString(), name: 'ERROR');
      throw HttpError.serverError;
    }
  }

  dynamic _handleResponse(Response? response) {
    developer.log(response!.data.toString(), name: 'RESPONSE');
    developer.log(response.statusCode.toString(), name: 'STATUSCODE');
    developer.log(
        '=========================================================================',
        name: 'END');

    switch (response.statusCode) {
      case 200:
        return response.data.isEmpty ? null : response.data;
      case 204:
        return null;
      case 400:
        final json = response.data;
        if (json.containsKey('error')) {
          return response.data.isEmpty ? null : json;
        }
        throw HttpError.badRequest;
      case 401:
        throw HttpError.unauthorized;
      case 403:
        throw HttpError.forbidden;
      case 404:
        throw HttpError.notFound;
      default:
        throw HttpError.serverError;
    }
  }
}
