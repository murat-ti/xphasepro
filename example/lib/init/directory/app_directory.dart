import 'package:path_provider/path_provider.dart';

class AppDirectory {
  static final AppDirectory _instance = AppDirectory._init();
  String? _path;
  static AppDirectory get instance => _instance;
  static String get path => instance._path!;

  AppDirectory._init() {
    getApplicationDocumentsDirectory().then((value) => _path = value.path);
  }

  static Future<dynamic> init() async {
    if (instance._path == null) {
      final dir = await getApplicationDocumentsDirectory();
      instance._path = dir.path;
    }
  }
}
