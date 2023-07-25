class ApplicationInfo {
  static const langAssetPath = 'assets/i18n';
}

class ApplicationApi {
  static const String serverUrl = 'http://192.168.6.1';
  static const int port8080 = 8080;
  static const int port8081 = 8081; //works only with get_file request
  //static const String filesPath = '$serverUrl/files';
  //static const String imageStorePath = '$serverUrl/images/store/';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 150);
  static const Duration sendTimeout = Duration(seconds: 300);
  static const bool loggerEnabled = false;
  //static const bool cacheEnabled = true;
  //static const Duration cacheTime = Duration(days: 1);
  static const snackbarDuration = 5;
  static const maxUploadFileSizeInMb = 10; //mb
}
