import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Helper chuyên biệt xử lý lưu trữ vĩnh viễn hình ảnh và âm thanh
/// trên mọi nền tảng (Web, Android, iOS, macOS) dưới dạng Data URI / Base64
/// để không bị mất khi thoát ứng dụng hoặc tải lại trang web.
class MediaPersistenceHelper {
  /// Chuyển đổi XFile từ ImagePicker thành chuỗi Base64 Data URI vĩnh cửu
  static Future<String> persistImage(XFile pickedFile) async {
    try {
      final bytes = await pickedFile.readAsBytes();
      final base64Str = base64Encode(bytes);

      String mime = 'image/jpeg';
      final pathLower = pickedFile.name.toLowerCase();
      if (pathLower.endsWith('.png')) {
        mime = 'image/png';
      } else if (pathLower.endsWith('.webp')) {
        mime = 'image/webp';
      }

      return 'data:$mime;base64,$base64Str';
    } catch (e) {
      debugPrint('Lỗi mã hóa ảnh vĩnh viễn: $e');
      return pickedFile.path;
    }
  }

  /// Chuyển đổi đường dẫn âm thanh (Blob URL trên web hoặc local file) thành Data URI
  static Future<String> persistAudio(String rawPath) async {
    if (rawPath.isEmpty) return rawPath;

    // Đã là Data URI sẵn
    if (rawPath.startsWith('data:audio')) {
      return rawPath;
    }

    try {
      Uint8List? audioBytes;
      String mime = 'audio/mp4';

      if (kIsWeb || rawPath.startsWith('blob:') || rawPath.startsWith('http')) {
        final uri = Uri.parse(rawPath);
        final response = await http.get(uri);
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          audioBytes = response.bodyBytes;
          if (rawPath.contains('webm') || (response.headers['content-type']?.contains('webm') ?? false)) {
            mime = 'audio/webm';
          }
        }
      } else {
        final file = io.File(rawPath);
        if (await file.exists()) {
          audioBytes = await file.readAsBytes();
          final lower = rawPath.toLowerCase();
          if (lower.endsWith('.wav')) {
            mime = 'audio/wav';
          } else if (lower.endsWith('.mp3')) {
            mime = 'audio/mp3';
          }
        }
      }

      if (audioBytes != null && audioBytes.isNotEmpty) {
        return 'data:$mime;base64,${base64Encode(audioBytes)}';
      }
    } catch (e) {
      debugPrint('Lỗi chuyển đổi âm thanh sang Data URI: $e');
    }

    return rawPath;
  }

  /// Trích xuất bytes từ chuỗi ảnh Data URI
  static Uint8List? decodeImageBytes(String path) {
    if (!path.startsWith('data:image')) return null;
    try {
      final comma = path.indexOf(',');
      final base64Part = comma != -1 ? path.substring(comma + 1) : path;
      return base64Decode(base64Part);
    } catch (e) {
      debugPrint('Lỗi giải mã base64 ảnh: $e');
      return null;
    }
  }

  /// Trích xuất bytes từ chuỗi âm thanh Data URI
  static Uint8List? decodeAudioBytes(String path) {
    if (!path.startsWith('data:audio')) return null;
    try {
      final comma = path.indexOf(',');
      final base64Part = comma != -1 ? path.substring(comma + 1) : path;
      return base64Decode(base64Part);
    } catch (e) {
      debugPrint('Lỗi giải mã base64 âm thanh: $e');
      return null;
    }
  }

  /// Nhận diện MIME type của Data URI
  static String extractMimeType(String dataUri, {String fallback = 'application/octet-stream'}) {
    if (!dataUri.startsWith('data:')) return fallback;
    final semicolon = dataUri.indexOf(';');
    if (semicolon != -1 && semicolon > 5) {
      return dataUri.substring(5, semicolon);
    }
    return fallback;
  }
}
