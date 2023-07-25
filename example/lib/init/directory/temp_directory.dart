import 'package:path_provider/path_provider.dart';

class TempDirectory {
  static final TempDirectory _instance = TempDirectory._init();
  String? _path;
  static TempDirectory get instance => _instance;
  static String get path => instance._path!;

  TempDirectory._init() {
    getTemporaryDirectory().then((value) => _path = value.path);
  }

  static Future<dynamic> init() async {
    if (instance._path == null) {
      final dir = await getTemporaryDirectory();
      instance._path = dir.path;
    }
  }
}
