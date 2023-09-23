import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../utils/helper.dart';
import 'connect.dart';
import 'enum/network_routes_path.dart';

class Camera {
  static const successStatus = 'OK';

  //static const mainURL = '${ApplicationApi.serverUrl}:${ApplicationApi.port8080}'; //getFile work on 8081
  static const mainURL = 'http://192.168.1.100/xphase/index.php';
  static const String _splitFrom = '\r\n';

  // Get capture and save status and ori file list from camera
  // based on GET http://192.168.6.1:8080/get_list
  // Response:
  // capture status]- 0:capture finished & OK; 1~253:capture finished & error; 254~255:capturing
  // [save status]- 0:save finished & OK; 1~253:save finished & error; 254~255:saving
  // [YYYY-MM-DD_hh-mm-ss]- ori file name without “.ori”
  static Future<List<String>?> get getList async {
    final url = '$mainURL/${NetworkRoutes.getList.path}';
    final response = await connect(url);

    if (response?.data != null && response!.data.isNotEmpty) {
      final result = response.data.split(_splitFrom);
      if (result.isNotEmpty) {
        final responseStatuses = result[0].split(',');
        if (responseStatuses.length == 2) {
          final captureStatus = int.tryParse(Helper.numberExtractor(responseStatuses[0])) ?? -1;
          final saveStatus = int.tryParse(Helper.numberExtractor(responseStatuses[1])) ?? -1;

          if (captureStatus == 0 && saveStatus == 0) {
            const textLength = 19;
            return result.where((element) => element.length == textLength).toList();
          } else {
            debugPrint('captureStatus: ${Helper.statusCheck(captureStatus, 'Capture')}');
            debugPrint('saveStatus: ${Helper.statusCheck(saveStatus, 'Save')}');
          }
        }
      }
    }
    return null;
  }

  static  Future<bool> get isSaved async {
    return (await Camera.getList) != null;
  }

  // Get exif information struct of one ori file from camera
  // based on GET http://192.168.6.1:8080/get_ parameters?filename=2020-02-03_12-04-05
  // Response:
  // Response status 200: exif information struct data (see sample code for detail)
  // Response status 404 (when ori file not found)
  /*static Future<Uint8List?> getParameters(String filename) async {
    final url = '${ApplicationApi.serverUrl}:${ApplicationApi.port8080}/${NetworkRoutes.getParameters.path}?filename=$filename';
    final response = await connect(url, RequestType.get);
    return response?.bodyBytes;
  }*/

  // Get exif information struct of one ori file from camera
  // based on http://192.168.6.1:8080/get_thumb?filename=2020-02-03_12-04-05
  // Response:
  // Response status 200: thumbnail jpg file data
  // Response status 404 (when ori file not found)
  static Future<void> getThumb(String filename, String downloadPath) async {
    final url = getThumbUrl(filename);
    await downloadDio(url: url, downloadPath: downloadPath);
  }

  //it is used for showing thumbs as network images in gallery
  static String getThumbUrl(String filename) {
    return '$mainURL/${NetworkRoutes.getThumb.path}?filename=$filename';
  }

  // Delete ori file from camera
  // based on http://192.168.6.1:8080/del_file?filename=2020-02-03_12-04-05
  // Response:
  // Response status 200: “OK”
  static Future<bool?> deleteFile(String filename) async {
    final url = '$mainURL/${NetworkRoutes.delFile.path}?filename=$filename';
    final response = await connect(url);
    return response?.data.contains(successStatus);
  }

  // Get ori from camera
  // based on http://192.168.6.1:8081/get_file?filename=2020-02-03_12-04-05
  // Response:
  // Response status 200: ori file data
  // Response status 404 (when ori file not found)
  static Future<Response?> getFile(
    String filename,
    String downloadPath,
    Function(int, int)? onReceiveProgress,
  ) async {
    var url = '$mainURL/${NetworkRoutes.getFile.path}?filename=$filename'.replaceAll('8080', '8081');
    //final response = await connect(url, RequestType.get);
    return await downloadDio(
      url: url,
      downloadPath: downloadPath,
      onReceiveProgress: onReceiveProgress,
    );
  }

  // Get the firmware version and the total space and available space of the U disk
  // based on http://192.168.6.1:8080/get_information
  // Response:
  // Response status 200:
  // disk_total=[total space in KB]\r\n
  // disk_free=[available space in KB]\r\n
  // firmware_version=[firmware version ID]\r\n
  static Future<Map<String, dynamic>?> get getInformation async {
    final url = '$mainURL/${NetworkRoutes.getInformation.path}';
    final response = await connect(url);

    if (response?.data != null && response!.data.isNotEmpty) {
      // disk_total=30047888
      // disk_free=24562880
      // firmware_version=20221101
      // device_id=4
      // serial_no=1733923329

      final result = response.data.split(_splitFrom);

      if (result.isNotEmpty && result.length > 3) {
        return {
          'disk_total': Helper.numberExtractor(result[0].split('=')[1]),
          'disk_free': Helper.numberExtractor(result[1].split('=')[1]),
          'firmware_version': Helper.numberExtractor(result[2].split('=')[1]),
        };
      } else {
        debugPrint('Information not available');
      }
    }

    return null;
  }

  // Stop time-lapse photography
  // based on http://192.168.6.1:8080/exit_timelapse
  // Response:
  // Response status 200: “OK”
  static Future<bool?> get exitTimelapse async {
    final url = '$mainURL/${NetworkRoutes.exitTimelapse.path}';
    var response = await connect(url);
    return response?.data.contains(successStatus);
  }

  // Turn off the camera
  // based on http://192.168.6.1:8080/shutdown
  // Response:
  // Response status 200: “OK”
  static Future<bool?> get shutdown async {
    final url = '$mainURL/${NetworkRoutes.shutdown.path}';
    var response = await connect(url);
    return response?.data.contains(successStatus);
  }

  // Format the udisk
  // based on http://192.168.6.1:8080/format_udisk
  // Response:
  // Response status 200: “OK”
  static Future<bool?> get formatUDisk async {
    final url = '$mainURL/${NetworkRoutes.formatUDisk.path}';
    var response = await connect(url);
    return response?.data.contains(successStatus);
  }

  // Config camera button setting and auto shutdown setting
  // based on http://192.168.6.1:8080/ config? btnsetting=1&shutdownmode=5
  // Parameter:
  // btnsetting=[0~1] Description: Camera button setting
  //    0:Default; 1:Last
  // shutdownmode=[0~5] Description: Auto shut down setting
  //    0:No; 1:5 Min; 2:10 Min; 3:15 Min; 4:20 Min; 5:30 Min
  // Response:
  // Response status 200: “OK”
  static Future<bool?> config(int btnSetting, int shutdownMode) async {
    final url = '$mainURL/${NetworkRoutes.config.path}?btnsetting=$btnSetting&shutdownmode=$shutdownMode';
    var response = await connect(url);
    return response?.data.contains(successStatus);
  }

  // send capture command to camera
  // based on http://192.168.6.1:8080/do_capture?capmode=4&strobemode=0&timelapse=0&isomode=1&evmode=128&exposure=20000&iso=100&delay=0&longitude=1164000000&latitude=400000000
  // Parameter:
  // capmode=[0~5] Description: auto/manual mode and hdr mode
  //    0:auto&hdr3; 1:manual&hdr3; 2:auto&hdr6; 3:manual&hdr6; 4:auto&hdr6+; 5:manual&hdr6+
  // strobemode=[0~2] Description: antiflicker mode
  //    0:close; 1:50Hz; 2:60Hz
  // timelapse=[0~7] time lapse mode
  //    0:no time lapse; 1: time lapse with interval 15s; 2: time lapse with interval 20s; 3: time lapse with interval 30s; 4: time lapse with interval 45s; 5: time lapse with interval 60s; 6: time lapse with interval 90s; 7: time lapse with interval 120s
  // isomode=[0~1] scene mode (no effect if capmode = 1, 3 or 5)
  //    0:handheld; 1:tripod
  // evmode=[119~137] Description: EV compensation setting (no effect if capmode = 1, 3 or 5)
  //    119:-3EV; 120:-8/3EV; …; 127:-1/3EV; 128:0EV; 129:+1/3EV; …; 136:+8/3EV; 137:+3EV
  // exposure=[250~8000000] Description: shutter speed in microsecond (no effect if capmode = 0, 2 or 4)
  //    250:250 microsecond; …; 8000000:8000000 microsecond
  // iso=[100-1600] Description: iso value (no effect if capmode = 0, 2 or 4)
  //    100:iso 100; …; 1600:iso 1600
  // delay=[0~8] Description: shutter timer setting
  //    0:no timer; 1:1 seconds timer; 2:2 seconds timer; 3:5 seconds timer; 4: 10 seconds timer; 5:15 seconds timer; 6:20 seconds timer; 7:30 seconds timer; 8:first 16 lens and then 9 lens
  // [Optional] longitude=[-1800000000~1800000000] Description: Integer((gps longitude value in degree) * 10000000)
  //    >0:East; <0:West; =0:No GPS
  // [Optional] latitude=[-900000000~900000000] Description: Integer(gps latitude value in degree) * 10000000)
  //    >0:North; <0:South; =0:No GPS
  // Response:
  // Response status 200: “OK”
  static Future<bool?> doCapture({
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
    final url =
        '$mainURL/${NetworkRoutes.doCapture.path}?capmode=$capmode&strobemode=$strobemode&timelapse=$timelapse&isomode=$isomode&evmode=$evmode&exposure=$exposure&iso=$iso&delay=$delay&longitude=$longitude&latitude=$latitude';
    var response = await connect(url);
    return response?.data.contains(successStatus);
  }
}
