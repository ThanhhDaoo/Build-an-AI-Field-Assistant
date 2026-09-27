import 'dart:typed_data';
import 'web_storage_stub.dart'
    if (dart.library.html) 'web_storage_web.dart' as impl;

class WebStorageHelper {
  static Future<bool> saveTickets(String jsonStr) => impl.saveTicketsImpl(jsonStr);

  static Future<String?> loadTickets() => impl.loadTicketsImpl();

  static Future<String?> compressImageToJpeg(
    Uint8List bytes, {
    int maxWidth = 1024,
    double quality = 0.75,
  }) => impl.compressImageToJpegImpl(bytes, maxWidth: maxWidth, quality: quality);
}
