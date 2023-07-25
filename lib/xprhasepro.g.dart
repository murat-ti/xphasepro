part of 'xphasepro.dart';

const String _libName = 'PanoMaker';

/// The dynamic library in which the symbols for [XphaseproBridge] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }

  //no need in implementation
  /*if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }*/
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final XPhaseProBridge _bridge = XPhaseProBridge(_dylib);