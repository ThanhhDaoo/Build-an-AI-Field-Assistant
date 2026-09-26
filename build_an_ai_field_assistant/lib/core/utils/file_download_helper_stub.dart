import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<void> downloadFileImpl({
  required String filename,
  required String content,
  required String mimeType,
}) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = io.File('${dir.path}/$filename');
    await file.writeAsString(content);
    debugPrint('File saved locally: ${file.path}');
  } catch (e) {
    debugPrint('Could not save file locally: $e');
  }
}
