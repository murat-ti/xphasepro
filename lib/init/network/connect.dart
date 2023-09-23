import 'package:flutter/foundation.dart' show debugPrint;
import 'enum/request_type.dart';
import 'package:dio/dio.dart';

BaseOptions options = BaseOptions(
  receiveDataWhenStatusError: true,
  connectTimeout: const Duration(seconds: 3),
  headers: {
    'Content-Type': 'application/json;charset=utf-8',
  },
  receiveTimeout: const Duration(seconds: 120),
);
var dio = Dio(options);

Future<Response?> connect(
  String url, {
  RequestType protocol = RequestType.get,
  int timeout = 3,
}) async {
  try {
    final request = await dio.get(url);

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
    //dio.close();
  }
}

Future<Response?> downloadDio({
  required String url,
  required String downloadPath,
  Function(int, int)? onReceiveProgress,
}) async {
  try {
    return await dio.get(
      url,
      //downloadPath,
      onReceiveProgress: onReceiveProgress,
      options: Options(
        responseType: ResponseType.bytes,
        // followRedirects: false,
        // validateStatus: (status) {
        //   return status < 500;
        // },
      ),
    );
    //debugPrint('Download Completed.');
  } catch (e) {
    debugPrint('Download Failed.\n\n$e');
    return null;
  }

}
