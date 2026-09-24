/// Core exception classes
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException([this.message = 'Lỗi máy chủ', this.statusCode]);

  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  const CacheException([this.message = 'Lỗi truy xuất dữ liệu cục bộ']);

  @override
  String toString() => 'CacheException: $message';
}

class AudioRecordingException implements Exception {
  final String message;

  const AudioRecordingException([this.message = 'Lỗi thiết bị thu âm giọng nói']);

  @override
  String toString() => 'AudioRecordingException: $message';
}

class MicrophonePermissionException implements Exception {
  final String message;
  final bool isPermanentlyDenied;

  const MicrophonePermissionException([
    this.message = 'Ứng dụng cần quyền truy cập Microphone để ghi âm biên bản sự cố.',
    this.isPermanentlyDenied = false,
  ]);

  @override
  String toString() => 'MicrophonePermissionException: $message (permanently: $isPermanentlyDenied)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'Không có kết nối mạng']);

  @override
  String toString() => 'NetworkException: $message';
}

class AiExtractionException implements Exception {
  final String message;
  final String? rawResponse;

  const AiExtractionException(
      [this.message = 'Lỗi trích xuất thông tin AI', this.rawResponse]);

  @override
  String toString() => 'AiExtractionException: $message\nRaw: $rawResponse';
}
