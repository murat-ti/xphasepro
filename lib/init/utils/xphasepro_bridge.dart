import 'dart:io';
import 'dart:ffi' as ffi;
import 'dart:typed_data' as td show Uint8List;
import 'package:dio/dio.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as path show basenameWithoutExtension;
import '../network/protocols.dart';
import 'type_converter.dart';

typedef ProInitRawFileReaderType = ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>, ffi.Int);
typedef ProInitRawFileReaderTypeDart = ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>, int);

typedef ProUpdateRawFileReaderType = ffi.Int Function(ffi.Pointer<ffi.Void>, ffi.Int);
typedef ProUpdateRawFileReaderTypeDart = int Function(ffi.Pointer<ffi.Void>, int);

typedef ProCleanRawFileReaderType = ffi.Int Function(ffi.Pointer<ffi.Void>);
typedef ProCleanRawFileReaderTypeDart = int Function(ffi.Pointer<ffi.Void>);

typedef ProMakePanoramaBufType = ffi.Int Function(
    ffi.Int,
    ffi.Int,
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Uint8>,
    ffi.Pointer<ffi.Uint8>,
    ffi.Int,
    ffi.Int,
    ffi.Int,
    ffi.Int,
    ffi.Int,
    ffi.Int,
    ffi.Int,
    ffi.Int,
    ffi.Int,
    ffi.Pointer<ffi.Uint8>,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Int,
    ffi.Int,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Double,
    ffi.Pointer<ffi.Uint8>);

typedef ProMakePanoramaBufTypeDart = int Function(
    int,
    int,
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Uint8>,
    ffi.Pointer<ffi.Uint8>,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    int,
    ffi.Pointer<ffi.Uint8>,
    double,
    double,
    double,
    int,
    int,
    double,
    double,
    double,
    double,
    ffi.Pointer<ffi.Uint8>);

// double ProGetProgress(double lastProgress, unsigned char* dbgData);
typedef ProGetProgressType = ffi.Double Function(ffi.Double, ffi.Pointer<ffi.Uint8>);
typedef ProGetProgressTypeDart = double Function(double, ffi.Pointer<ffi.Uint8>);

class XPhaseProBridge {
  late final ProInitRawFileReaderTypeDart _proInitRawFileReaderType;
  late final ProUpdateRawFileReaderTypeDart _proUpdateRawFileReaderType;
  late final ProCleanRawFileReaderTypeDart _proCleanRawFileReaderType;
  late final ProMakePanoramaBufTypeDart _proMakePanoramaBufTypeDart;
  late final ProGetProgressTypeDart _proGetProgressTypeDart;

  //final ffi.Pointer<ffi.Uint8> dbgDataPtr = TypeConverter.castToCFRomList(data: List<int>.filled(256, 0, growable: false));

  XPhaseProBridge(ffi.DynamicLibrary dynamicLibrary) {
    _proInitRawFileReaderType =
        dynamicLibrary.lookupFunction<ProInitRawFileReaderType, ProInitRawFileReaderTypeDart>('ProInitRawFileReader');

    _proUpdateRawFileReaderType = dynamicLibrary
        .lookupFunction<ProUpdateRawFileReaderType, ProUpdateRawFileReaderTypeDart>('ProUpdateRawFileReader');

    _proCleanRawFileReaderType = dynamicLibrary
        .lookupFunction<ProCleanRawFileReaderType, ProCleanRawFileReaderTypeDart>('ProCleanRawFileReader');

    _proMakePanoramaBufTypeDart =
        dynamicLibrary.lookupFunction<ProMakePanoramaBufType, ProMakePanoramaBufTypeDart>('ProMakePanoramaBuf');

    _proGetProgressTypeDart =
        dynamicLibrary.lookupFunction<ProGetProgressType, ProGetProgressTypeDart>('ProGetProgress');
  }

  int getPointer() {
    final ffi.Pointer<ffi.Uint8> dbgDataPtr =
        TypeConverter.castToCFRomList(data: List<int>.filled(256, 0, growable: false));
    debugPrint(dbgDataPtr.toString());
    return dbgDataPtr.address;
  }

  Future<int> convertImage({
    required String inputPath,
    required String outputPath,
    required int threadNum,
    required int memType,
    required int hdrSel,
    required int outputType,
    required int colorMode,
    required int extendMode,
    required int outputJpgType,
    required int outputQuality,
    required int stitchMode,
    required int gyroMode,
    required int templateMode,
    required double logoAngle,
    required double luminance,
    required double contrastRatio,
    required int gammaMode,
    required int wbMode,
    required double wbConfB,
    required double wbConfG,
    required double wbConfR,
    required double saturation,
    required int pointer,
  }) async {
    int result = -1;
    //const threadNum = 4; //should be 4
    //const memType = 0; //should be 0
    // rawFileReader => handle of “RawFileReader” created by “ProInitRawFileReader”
    // outputDirPtr => folder path to hold output file. Should end with char ‘/’
    // inputFilenamePtr => ori file name without “.ori”, with the pattern “YYYY-MM-DD_hh-mm-ss”
    //const hdrSel = 10; //hdr merge or not => 10:hdr merge
    //const outputType = 0; //0:jpg
    //const colorMode = 1; //should be 1 if outputType is 0
    //const extendMode = 0; //should be 0
    //const outputJpgType = 1; //Range [0~1]  0: YUV420; 1: YUV444
    //const outputQuality = 90; //Range [70~99] quality of output jpg file
    //const stitchMode = 0; //select sence for hdr merge optimization => Range [0~1]  0: Motion; 1: Static
    //const gyroMode = 0; //whether to use gyroscope for level correction => Range [0~1]  0:no correction; 1: correction
    //const templateMode = 0; //For normal stitch: Range [0]
    //strEmptyPtr => For normal stitch: should be “”
    //const logoAngle = -1.0; //Should be -1.0
    //const luminance = 1.2; //luminance of output panoramic photo =>	Range [1.0~1.5] 1.0: darkest; 1.5: brightest
    //const contrastRatio =
    //1.3; //contrast of output panoramic photo =>	Range [1.0~1.5] 1.0: lowest contrast; 1.5: highest contrast
    //const gammaMode =
    //    1; //gamma curve of output panoramic photo =>	Range [0~1]  0: shadow is darker; 1: shadow is brighter
    //const wbMode = 0; //select white balance mode => Range [0~2]  0: auto; 1: indoor; 2: manual
    //const wbConfB =
    //    1.0; //manual white balance ratio for blue channel (no effect if wbMode = 0) => Range [0.5~2.0] 0.5: least blue; 2.0: most blue
    //const wbConfG =
    //    1.0; //manual white balance ratio for green channel (no effect if wbMode = 0) => Range [0.5~2.0] 0.5: least green; 2.0: most green
    //const wbConfR =
    //    1.0; //manual white balance ratio for red channel (no effect if wbMode = 0) =>	Range [0.5~2.0] 0.5: least red; 2.0: most red
    //const saturation = 1.0; // Should be 1.0
    //dbgDataPtr => debug data buffer to hold stitching progress and debug information. Size of dbgData should >= 256. dbgData should be initialized with 0

    late final ffi.Pointer<ffi.Uint8> oriFileBufPtr;
    late final ffi.Pointer<ffi.Uint8> outputDirPtr;
    late final ffi.Pointer<ffi.Uint8> inputFilenamePtr;
    late final ffi.Pointer<ffi.Uint8> strEmptyPtr;
    //late final ffi.Pointer<ffi.Uint8> dbgDataPtr;
    final ffi.Pointer<ffi.Uint8> dbgDataPtr = ffi.Pointer<ffi.Uint8>.fromAddress(pointer);

    try {
      String oriFilename = path.basenameWithoutExtension(inputPath); //'2023-07-01_00-00-00';
      //debugPrint('ori path $inputPath');
      //debugPrint('output path $outputPath');
      File file = File(inputPath);
      int fileSize = file.lengthSync();

      // Response? response = await Camera.getFile(oriFilename, '', (int received, int total) {
      //   print('Downloading: ${((received / total) * 100).floor()}');
      // });
      //
      // print('response.headers');
      // print(response?.headers['content-length']);
      // print(response?.data.runtimeType);
      //
      // final contentLength = response?.headers['content-length'];
      // final fileSize = int.tryParse(contentLength![0]) ?? 0;
      print('File size $fileSize');
      //td.Uint8List data = file.readAsBytesSync();
      WeakReference<td.Uint8List> weakReferenceData = WeakReference(file.readAsBytesSync());
      //WeakReference<td.Uint8List> weakReferenceData = WeakReference(response?.data);
      if (weakReferenceData.target != null) {
        oriFileBufPtr = TypeConverter.castToC(data: weakReferenceData.target!);

        //ProInitRawFileReader will create a RawFileReader and return its handle
        ffi.Pointer<ffi.Void> rawFileReader = _proInitRawFileReaderType(oriFileBufPtr, fileSize);
        debugPrint('RawFileReader was initialized');

        //ProUpdateRawFileReader will notify RawFileReader write position of the file buffer
        int value = _proUpdateRawFileReaderType(rawFileReader, fileSize);
        debugPrint('ProUpdateRawFileReader result: $value');

        //type cast operations
        outputDirPtr = TypeConverter.castToCFRomList(data: outputPath.codeUnits);
        inputFilenamePtr = TypeConverter.castToCFRomList(data: oriFilename.codeUnits);
        strEmptyPtr = TypeConverter.castToCFRomList(data: ''.codeUnits);
        //dbgDataPtr = TypeConverter.castToCFRomList(data: List<int>.filled(256, 0, growable: false));

        debugPrint('Start converting: $oriFilename => $outputPath');

        //ProMakePanoramaBuf will stitch ori file and generate panoramic jpg
        result = _proMakePanoramaBufTypeDart(
          threadNum,
          memType,
          rawFileReader,
          outputDirPtr,
          inputFilenamePtr,
          hdrSel,
          outputType,
          colorMode,
          extendMode,
          outputJpgType,
          outputQuality,
          stitchMode,
          gyroMode,
          templateMode,
          strEmptyPtr,
          logoAngle,
          luminance,
          contrastRatio,
          gammaMode,
          wbMode,
          wbConfB,
          wbConfG,
          wbConfR,
          saturation,
          dbgDataPtr,
        );

        debugPrint('Start cleaning operations');
        //ProCleanRawFileReader will release RawFileReader
        value = _proCleanRawFileReaderType(rawFileReader);
        debugPrint('Cleaning result: $value');
      } else {
        debugPrint('weakReferenceData is null');
      }

    } catch (e) {
      debugPrint('Exception: ${e.toString()}');
    } finally {
      //Releases memory allocated on the native heap
      calloc.free(oriFileBufPtr);
      calloc.free(outputDirPtr);
      calloc.free(inputFilenamePtr);
      calloc.free(strEmptyPtr);
      calloc.free(dbgDataPtr);
      debugPrint('Memory released');
    }

    return result;
  }

  double getProgress({required double lastProgress, required int pointer}) {
    final dbgDataPtr = ffi.Pointer<ffi.Uint8>.fromAddress(pointer);
    //debugPrint('getProgress pointer: $pointer => $dbgDataPtr');
    lastProgress = _proGetProgressTypeDart(lastProgress, dbgDataPtr);
    return lastProgress;
  }
}
