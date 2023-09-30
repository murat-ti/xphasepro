import 'dart:async' show Future;
import 'dart:ffi' show DynamicLibrary;
import 'dart:io' show Platform;
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'init/network/protocols.dart';
import 'init/utils/xphasepro_bridge.dart';

part 'xprhasepro.g.dart';

Future<List<String>?> getList() async {
  return Camera.getList;
}

Future<bool> isSaved() async {
  return Camera.isSaved;
}

Future<Response?> getThumb(String filename, String downloadPath) async {
  return Camera.getThumb(filename, downloadPath);
}

String getThumbUrl(String filename) {
  return Camera.getThumbUrl(filename);
}

Future<bool?> deleteFile(String filename) async {
  return Camera.deleteFile(filename);
}

Future<Response?> getFile(String filename, String downloadPath, {Function(int, int)? onReceiveProgress}) async {
  return Camera.getFile(filename, downloadPath, onReceiveProgress);
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

int getPointer() {
  return _bridge.getPointer();
}

/// Converts ori file to jpeg.
Future<int?> convertOriToJpg({
  required String inputPath,
  required String outputPath,
  required int pointer,
  int threadNum = 4,
  int memType = 0,
  int hdrSel = 10,
  int outputType = 0,
  int colorMode = 1,
  int extendMode = 0,
  int outputJpgType = 1,
  int outputQuality = 90,
  int stitchMode = 0,
  int gyroMode = 0,
  int templateMode = 0,
  double logoAngle = -1.0,
  double luminance = 1.2,
  double contrastRatio = 1.3,
  int gammaMode = 1,
  int wbMode = 0,
  double wbConfB = 1.0,
  double wbConfG = 1.0,
  double wbConfR = 1.0,
  double saturation = 1.0,
}) async {
  return await Isolate.run(
    () => _bridge.convertImage(
      inputPath: inputPath,
      outputPath: outputPath,
      threadNum: threadNum,
      memType: memType,
      hdrSel: hdrSel,
      outputType: outputType,
      colorMode: colorMode,
      extendMode: extendMode,
      outputJpgType: outputJpgType,
      outputQuality: outputQuality,
      stitchMode: stitchMode,
      gyroMode: gyroMode,
      templateMode: templateMode,
      logoAngle: logoAngle,
      luminance: luminance,
      contrastRatio: contrastRatio,
      gammaMode: gammaMode,
      wbMode: wbMode,
      wbConfB: wbConfB,
      wbConfG: wbConfG,
      wbConfR: wbConfR,
      saturation: saturation,
      pointer: pointer,
    ),
  );
  /*return _bridge.convertImage(
    inputPath: inputPath,
    outputPath: outputPath,
  );*/
}

/// Get progress
Future<double?> getConvertingProgress({
  double lastProgress = 0.0,
  required int pointer,
}) async {
  return await Isolate.run(
    () => _bridge.getProgress(
      lastProgress: lastProgress,
      pointer: pointer,
    ),
  );
}
