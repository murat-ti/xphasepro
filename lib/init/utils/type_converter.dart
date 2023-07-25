import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' show calloc;
import 'dart:typed_data' as td show Uint8List;

class TypeConverter {
  // NOTE: dont forget to call free() on buf created by this!
  static ffi.Pointer<ffi.Uint8> castToC({required td.Uint8List data}) {
    ffi.Pointer<ffi.Uint8> ptr = calloc<ffi.Uint8>(data.length);
    for (int i = 0; i < data.length; i++) {
      ptr[i] = data[i];
    }
    return ptr;
  }

  static ffi.Pointer<ffi.Uint8> castToCFRomList({required List<int> data}) {
    return castToC(data: td.Uint8List.fromList(data));
  }
}