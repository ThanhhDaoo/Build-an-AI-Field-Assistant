import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart' as download_impl;

/// Helper tải file xuống an toàn trên mọi nền tảng (Web, Mobile, Desktop)
class FileDownloadHelper {
  static Future<void> downloadFile({
    required String filename,
    required String content,
    String mimeType = 'text/csv;charset=utf-8',
  }) async {
    await download_impl.downloadFileImpl(
      filename: filename,
      content: content,
      mimeType: mimeType,
    );
  }
}
