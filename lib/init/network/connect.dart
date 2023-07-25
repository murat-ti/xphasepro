import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'enum/request_type.dart';

const Map<String, String> _headers = {'Content-Type': 'application/json;charset=utf-8'};

Future<http.Response?> connect(String url, {RequestType protocol = RequestType.get, int timeout = 30}) async {
  var client = http.Client();
  try {
    final request = await client.get(Uri.parse(url), headers: _headers).timeout(
          Duration(seconds: timeout),
          onTimeout: () => http.Response('Error timeout', 408),
        );

    if (request.statusCode == 200) {
      return request;
    } else {
      debugPrint('Request status code: ${request.statusCode}');
      return null;
    }
  } catch (error) {
    debugPrint('Error: ${error.toString()}');
    return null;
  } finally {
    client.close();
  }
}

Future<http.StreamedResponse> download({required String url, required String downloadPath}) {
  final httpClient = http.Client();
  final request = http.Request('GET', Uri.parse(url));
  final response = httpClient.send(request);
  return response;
}
