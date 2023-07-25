import 'dart:async' show Future;
import 'dart:ffi' show DynamicLibrary;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:isolate';
import 'package:xphasepro/init/network/protocols.dart';

import 'init/utils/xphasepro_bridge.dart';

part 'xprhasepro.g.dart';

Future<List<String>?> getList() async {
  return Camera.getList;
}

Future<http.StreamedResponse> getThumb(String filename, String downloadPath) async {
  return Camera.getThumb(filename, downloadPath);
}

Future<bool?> deleteFile(String filename) async {
  return Camera.deleteFile(filename);
}

Future<http.StreamedResponse> getFile(String filename, String downloadPath) async {
  return Camera.getFile(filename, downloadPath);
}

Future<Map<String, dynamic>?> getInformation() async {
  return Camera.getInformation;
}

Future<bool?> exitTimelapse() async {
  return Camera.exitTimelapse;
}

Future<bool?> shutdown() async {
  return Camera.shutdown;
}

Future<bool?> formatUDisk() async {
  return Camera.formatUDisk;
}

Future<bool?> configCamera(int btnSetting, int shutdownMode) async {
  return Camera.config(btnSetting, shutdownMode);
}

Future<bool?> doCapture({
  required int capmode,
  required int strobemode,
  required int timelapse,
  required int isomode,
  required int evmode,
  required int exposure,
  required int iso,
  required int delay,
  required int longitude,
  required int latitude,
}) async {
  return Camera.doCapture(
    capmode: capmode,
    strobemode: strobemode,
    timelapse: timelapse,
    isomode: isomode,
    evmode: evmode,
    exposure: exposure,
    iso: iso,
    delay: delay,
    longitude: longitude,
    latitude: latitude,
  );
}

/// Converts ori file to jpeg.
Future<int?> convertOriToJpg({
  required String inputPath,
  required String outputPath,
}) async {
  return await Isolate.run(
    () => _bridge.convertImage(
      inputPath: inputPath,
      outputPath: outputPath,
    ),
  );
  /*return _bridge.convertImage(
    inputPath: inputPath,
    outputPath: outputPath,
  );*/
}

/// Get progress
Future<double?> getConvertingProgress({double lastProgress = 0.0}) async {
  return _bridge.getProgress(lastProgress: lastProgress);
}
