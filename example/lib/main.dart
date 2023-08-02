import 'dart:async' show StreamSubscription;
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:xphasepro_example/init/enum/camera_actions.dart';
import 'init/directory/temp_directory.dart';
import 'package:xphasepro/xphasepro.dart' as xphasepro;
import 'dart:typed_data' show Uint8List;
import 'package:async/async.dart';
import 'package:http/http.dart' as http;

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
                            /*buildButtonPadding(const Text('Get Thumb'), () async {
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
                              setSubActiveIndex(
                                  index, status != null ? 'image delete status: $status' : 'error occurs');
                            }),*/
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

  void setSubActiveIndex(index, text) {
    setState(() {
      currentSubActionIndex = index;
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
    getListItems = ['2030-01-01_10-40-53','2030-01-01_10-40-53','2030-01-01_10-40-53'];
    /*final response = await xphasepro.getList();
    if (response != null) {
      getListItems = response;
      infoText = '';
    } else {
      infoText = 'error occurs';
    }*/

    //update ui
    setState(() {});
  }

  Future<void> getThumb(String filenameWoExt, int index) async {
    var downloadPath = '${TempDirectory.path}/$filenameWoExt.jpg';
    downloadFile(
      response: xphasepro.getThumb(filenameWoExt, downloadPath),
      downloadPath: downloadPath,
      index: index,
    );
  }

  Future<bool?> deleteFile(String filenameWoExt) async {
    final response = await xphasepro.deleteFile(filenameWoExt);
    return response;
  }

  Future<void> getFile(String filenameWoExt, int index) async {
    var downloadPath = '${TempDirectory.path}/$filenameWoExt.ori';
    downloadFile(
      response: xphasepro.getFile(filenameWoExt, downloadPath),
      downloadPath: downloadPath,
      index: index,
    );
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
    final stopwatch = Stopwatch()..start();
    int? result;
    final String oriPath = path.join(TempDirectory.path, '$filenameWoExt.ori');

    final file = File(oriPath);

    if (!file.existsSync()) {
      setSubActiveIndex(index, 'The ori file not found in $oriPath');
    } else {
      try {
        //double? progress = await xphasepro.getConvertingProgress() ?? 0.0;
        setSubActiveIndex(index, 'Converting started...');
        result = await xphasepro.convertOriToJpg(inputPath: oriPath, outputPath: '${TempDirectory.path}/');
        final outputFileName = '$filenameWoExt.jpg';
        if (result == 0) {
          jpgPath = path.join(TempDirectory.path, outputFileName);
        } else {
          jpgPath = null;
        }
        //progress = await xphasepro.getConvertingProgress(lastProgress: progress);
        setSubActiveIndex(index, 'Result: $result');
      } catch (e) {
        final result = e.toString();
        if (result.contains('x86/libPanoMaker.so')) {
          setSubActiveIndex(index, 'It does not work on emulator. No support for x86 processor.');
        } else {
          setSubActiveIndex(index, e.toString());
        }
      } finally {
        if (result == 0) {
          setSubActiveIndex(index, 'Completed execution in ${stopwatch.elapsed.inSeconds} seconds');
        }
      }
    }
  }

  /*Future<void> removeJpgImage() async {
    String tempPath = path.join(TempDirectory.path, outputFileName);
    if (File(tempPath).existsSync()) {
      File(tempPath).deleteSync();
      setState(() {
        jpgPath = null;
      });
    }
  }*/

  void downloadFile({
    required Future<http.StreamedResponse> response,
    required String downloadPath,
    required int index,
  }) {
    // Download file as a stream
    List<List<int>> chunks = [];
    int totalSize = 0;
    int downloaded = 0;
    late StreamSubscription<http.StreamedResponse> subscription;
    late final Uint8List bytes;

    subscription = response.asStream().listen((http.StreamedResponse r) async {
      debugPrint('Start get file size');
      if (r.headers['content-length'] != null) {
        totalSize = int.parse(r.headers['content-length']!);
        debugPrint('File size: ${totalSize ~/ 1024 ~/ 1024}MB');
      }
      final reader = ChunkedStreamReader(r.stream);
      try {
        // Set buffer size to 64KB
        int chunkSize = 64 * 1024;

        Uint8List buffer;

        do {
          buffer = await reader.readBytes(chunkSize);
          // Add buffer to chunks list
          chunks.add(buffer);
          downloaded += buffer.length;

          setSubActiveIndex(index, 'Downloading: ${downloaded ~/ 1024 ~/ 1024}MB from ${totalSize ~/ 1024 ~/ 1024}MB');
        } while (buffer.length == chunkSize);


        // Write chunks to file
        File file = File(downloadPath);

        //this approach constantly increase memory
        //final Uint8List bytes = Uint8List(r.contentLength!);

        //this approach helps to release memory
        WeakReference<Uint8List> weakReferenceBytes = WeakReference(Uint8List(r.contentLength!));

        int offset = 0;
        for (List<int> chunk in chunks) {
          /*bytes.setRange(offset, offset + chunk.length, chunk);
          offset += chunk.length;*/
          if(weakReferenceBytes.target != null) {
            weakReferenceBytes.target!.setRange(offset, offset + chunk.length, chunk);
            offset += chunk.length;
          }
        }

        //await file.writeAsBytes(bytes);
        if(weakReferenceBytes.target != null) {
          await file.writeAsBytes(weakReferenceBytes.target!);
        }

        setSubActiveIndex(index, 'File downloaded');
      } catch (e) {
        debugPrint(e.toString());
      } finally {
        reader.cancel();
        subscription.cancel();
      }
    });
  }
}
