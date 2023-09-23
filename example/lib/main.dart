import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:xphasepro_example/init/enum/camera_actions.dart';
import 'init/directory/temp_directory.dart';
import 'package:xphasepro/xphasepro.dart' as xphasepro;
import 'package:dio/dio.dart' show Response;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool showLoading = false;
  CameraActions _currentAction = CameraActions.noAction;
  List<String> getListItems = [];
  String infoText = '';
  int currentSubActionIndex = -1;
  double? progress = 0.0;
  int pointer = 0;
  int currentIndex = 0;

  String? jpgPath;

  @override
  void initState() {
    super.initState();

    TempDirectory.init().then(
      (value) {
        debugPrint('Temp dir is initialized');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: showLoading
          ? const CircularProgressIndicator()
          : SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text('Main Actions'),
                  buildMainActionsBox(),
                  _currentAction == CameraActions.getList ? buildGetListActionsBox() : buildInfoBox(),
                  //buildImageView(),
                  //buildOriImageActionsBox(),
                ],
              ),
            ),
    );
  }

  /*Widget buildOriImageActionsBox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: startConvert,
          child: const Text('Start stitch'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),

        jpgPath != null
            ? ElevatedButton(
                onPressed: removeJpgImage,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Remove ori image'),
              )
            : const SizedBox.shrink(),
      ],
    );
  }*/

  buildMainActionsBox() {
    return SizedBox(
      height: 50,
      child: ListView(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        children: [
          buildButtonPadding(const Text('Get List'), getList, _currentAction == CameraActions.getList),
          /*buildButtonPadding(
              const Text('Get Information'), getInformation, _currentAction == CameraActions.getInformation),
          buildButtonPadding(
              const Text('Exit Timelapse'), exitTimelapse, _currentAction == CameraActions.exitTimelapse),
          buildButtonPadding(const Text('Shutdown'), shutdown, _currentAction == CameraActions.shutdown),
          buildButtonPadding(const Text('Format UDisk'), formatUDisk, _currentAction == CameraActions.formatUDisk),
          buildButtonPadding(
            const Text('Config camera'),
            () => configCamera(btnSetting: 0, shutdownMode: 0),
            _currentAction == CameraActions.configCamera,
          ),
          buildButtonPadding(
            const Text('Do Capture'),
            () => doCapture(
              capmode: 0,
              strobemode: 0,
              timelapse: 0,
              isomode: 0,
              evmode: 119,
              exposure: 250,
              iso: 100,
              delay: 0,
              longitude: 0,
              latitude: 0,
            ),
            _currentAction == CameraActions.doCapture,
          ),*/
        ],
      ),
    );
  }

  Widget buildInfoBox() {
    return Text(infoText);
  }

  Widget buildGetListActionsBox() {
    return (getListItems.isEmpty && infoText.isNotEmpty)
        ? buildInfoBox()
        : Expanded(
            child: SizedBox(
              height: 300,
              child: ListView.builder(
                shrinkWrap: false,
                itemCount: getListItems.length,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [
                      SizedBox(
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Align(
                                //alignment: Alignment.center,
                                child: Text(getListItems[index]),
                              ),
                            ),
                            buildButtonPadding(const Text('Get Thumb'), () async {
                              //String? filename = await getThumb(getListItems[index]);
                              //setSubActiveIndex(index, filename != null ? 'File saved in $filename' : 'error occurs');
                              getThumb(getListItems[index], index);
                            }),
                            buildButtonPadding(const Text('Get File'), () async {
                              //String? filename = await getFile(getListItems[index]);
                              //setSubActiveIndex(index, filename != null ? 'File saved in $filename' : 'error occurs');
                              getFile(getListItems[index], index);
                            }),
                            buildButtonPadding(const Text('Delete File'), () async {
                              bool? status = await deleteFile(getListItems[index]);
                              setSubActiveIndex(status != null ? 'image delete status: $status' : 'error occurs',
                                  index: index);
                            }),
                            //buildOriImageActionsBox(),
                            buildButtonPadding(
                              const Text('Start stitch'),
                              () async => startConvert(getListItems[index], index),
                              false,
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                      index == currentSubActionIndex ? Text(infoText) : const SizedBox.shrink(),
                    ],
                  );
                },
              ),
            ),
          );
  }

  Widget buildImageView() {
    int imageWidth = MediaQuery.of(context).size.width.toInt();
    return jpgPath != null
        ? Image.file(
            File(jpgPath!),
            cacheHeight: (imageWidth / 2).round(),
            cacheWidth: imageWidth,
          )
        : const Text('No jpg file found.');
  }

  Widget buildButtonPadding(Widget child, Function()? onPressed, [bool activeAction = false, Color? backgroundColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: backgroundColor ?? (activeAction ? Colors.red : Colors.blue)),
        child: child,
      ),
    );
  }

  void resetActions(CameraActions action) {
    _currentAction = action;
    getListItems = [];
    infoText = '';
    currentSubActionIndex = -1;
  }

  void setSubActiveIndex(text, {int? index}) {
    setState(() {
      currentSubActionIndex = index ?? currentSubActionIndex;
      infoText = text;
    });
  }

  void setInfoText(text) {
    setState(() {
      infoText = text;
    });
  }

  Future<void> getList() async {
    resetActions(CameraActions.getList);
    //getListItems = ['2030-01-01_10-40-53','2030-01-01_10-40-53','2030-01-01_00-00-00'];
    final response = await xphasepro.getList();
    if (response != null) {
     getListItems = response;
     infoText = '';
    } else {
     infoText = 'error occurs';
    }
    // final response = await xphasepro.getList();
    // getListItems = response ?? [];
    // if (getListItems.isNotEmpty) {
    //   for (int i = 0; i < getListItems.length; i++) {
    //     //print('Delay 3 sec');
    //     infoText = '';
    //     //getListItems = ['2030-01-01_10-40-53'];
    //     const jpgTitle = '2023-07-03_18.47.23';
    //     //var downloadPath = '${TempDirectory.path}/${getListItems[0]}.ori';
    //     //print('$i download start');
    //     /*await xphasepro.getFile(getListItems[0], downloadPath, (int received, int total) {
    //       setSubActiveIndex(i, 'Downloading: ${((received / total) * 100).floor()}');
    //     });*/
    //     //print('$i download end');
    //
    //     await startConvert(getListItems[i], 0);
    //
    //     //print('remove $downloadPath');
    //     //await File(downloadPath).delete();
    //
    //     var jpgPath = '${TempDirectory.path}/$jpgTitle.jpg';
    //     print('remove $jpgPath');
    //     if (File(jpgPath).existsSync()) {
    //       await File(jpgPath).delete();
    //     }
    //
    //     await Future.delayed(const Duration(seconds: 3));
    //
    //     /*if(i == 2) {
    //       //call for run GC
    //       print('call another action for run GC');
    //       await xphasepro.getFile(getListItems[0], downloadPath, (int received, int total) {
    //         setSubActiveIndex(i, 'Downloading: ${((received / total) * 100).floor()}');
    //       });
    //     }*/
    //
    //     infoText = '';
    //   }
    // } else {
    //   infoText = 'error occurs';
    // }

    //update ui
    setState(() {});
  }

  Future<void> getThumb(String filenameWoExt, int index) async {
    var downloadPath = '${TempDirectory.path}/$filenameWoExt.jpg';
    /*downloadFile(
      response: xphasepro.getThumb(filenameWoExt, downloadPath),
      downloadPath: downloadPath,
      index: index,
    );*/
    await xphasepro.getThumb(filenameWoExt, downloadPath);
    setSubActiveIndex(File(downloadPath).existsSync() ? 'downloaded' : 'error occurs', index: index);
  }

  Future<bool?> deleteFile(String filenameWoExt) async {
    final response = await xphasepro.deleteFile(filenameWoExt);
    return response;
  }

  Future<void> getFile(String filenameWoExt, int index) async {
    var downloadPath = '${TempDirectory.path}/$filenameWoExt.ori';
    /*downloadFile(
      response: xphasepro.getFile(filenameWoExt, downloadPath),
      downloadPath: downloadPath,
      index: index,
    );*/
    Response? response = await xphasepro.getFile(filenameWoExt, downloadPath, onReceiveProgress: (int received, int total) {
      setSubActiveIndex('Downloading: ${((received / total) * 100).floor()}',index:index);
    });
    print('response.headers');
    print(response?.headers['content-length']);
    print(response?.data.runtimeType);
    setSubActiveIndex(File(downloadPath).existsSync() ? 'Downloaded' : 'error occurs', index: index);
  }

  Future<void> getInformation() async {
    resetActions(CameraActions.getInformation);

    final response = await xphasepro.getInformation();
    setInfoText(response != null ? response.toString() : 'error occurs');
  }

  Future<void> exitTimelapse() async {
    resetActions(CameraActions.exitTimelapse);

    final response = await xphasepro.exitTimelapse();
    setInfoText(response != null ? 'exit Timelapse status: $response' : 'error occurs');
  }

  Future<void> shutdown() async {
    resetActions(CameraActions.shutdown);

    final response = await xphasepro.shutdown();
    setInfoText(response != null ? 'shutdown status: $response' : 'error occurs');
  }

  Future<void> formatUDisk() async {
    resetActions(CameraActions.formatUDisk);

    final response = await xphasepro.formatUDisk();
    setInfoText(response != null ? 'Format UDisk status: $response' : 'error occurs');
  }

  Future<void> configCamera({int btnSetting = 0, int shutdownMode = 0}) async {
    resetActions(CameraActions.configCamera);

    final response = await xphasepro.configCamera(btnSetting, shutdownMode);
    setInfoText(response != null ? 'Config status: $response' : 'error occurs');
  }

  Future<void> doCapture({
    int capmode = 0,
    int strobemode = 0,
    int timelapse = 0,
    int isomode = 0,
    int evmode = 119,
    int exposure = 250,
    int iso = 100,
    int delay = 0,
    int longitude = 0,
    int latitude = 0,
  }) async {
    resetActions(CameraActions.doCapture);

    final response = await xphasepro.doCapture(
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
    setInfoText(response != null ? 'Do capture status: $response' : 'error occurs');
  }

  Future<void> startConvert(String filenameWoExt, int index) async {
    Timer? timer;
    final stopwatch = Stopwatch()..start();
    int? result;
    final String oriPath = path.join(TempDirectory.path, '$filenameWoExt.ori');

    final file = File(oriPath);

    if (!file.existsSync()) {
      setSubActiveIndex('The ori file not found in $oriPath', index: index);
    } else {
      try {
        //double? progress = await xphasepro.getConvertingProgress() ?? 0.0;
        setSubActiveIndex('Converting started...', index: index);
        pointer = xphasepro.getPointer();
        timer = Timer.periodic(const Duration(seconds: 3), getProgressInTimer);
        result = await xphasepro.convertOriToJpg(
          inputPath: oriPath,
          outputPath: '${TempDirectory.path}/',
          pointer: pointer,
        );
        final outputFileName = '$filenameWoExt.jpg';
        if (result == 0) {
          jpgPath = path.join(TempDirectory.path, outputFileName);
        } else {
          jpgPath = null;
        }
        setSubActiveIndex('Result: $result', index: index);
      } catch (e) {
        final result = e.toString();
        if (result.contains('x86/libPanoMaker.so')) {
          setSubActiveIndex('It does not work on emulator. No support for x86 processor.', index: index);
        } else {
          setSubActiveIndex(e.toString(), index: index);
        }
      } finally {
        timer?.cancel();
        progress = 0.0;
        pointer = 0;
        if (result == 0) {
          setSubActiveIndex('Completed execution in ${stopwatch.elapsed.inSeconds} seconds', index: index);
        }
      }
    }
  }

  Future<void> getProgressInTimer(Timer t) async {
    progress = progress ?? 0;
    progress = await xphasepro.getConvertingProgress(
      lastProgress: progress!,
      pointer: pointer,
    );

    //currentSubActionIndex
    setSubActiveIndex('Converting progress: ${(progress! * 100.0).toStringAsFixed(2)}%');
    //debugPrint('${(progress! * 100.0).toStringAsFixed(2)}%');
  }
}
