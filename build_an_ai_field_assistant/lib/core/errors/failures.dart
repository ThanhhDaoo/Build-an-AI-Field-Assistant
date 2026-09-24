/// Base Failure representation for Clean Architecture
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Không thể kết nối đến máy chủ AI']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Không thể lưu hoặc đọc dữ liệu offline']);
}

class AudioFailure extends Failure {
  const AudioFailure([super.message = 'Không thể thu âm hoặc xử lý âm thanh']);
}

class MicrophonePermissionFailure extends Failure {
  final bool isPermanentlyDenied;

  const MicrophonePermissionFailure([
    super.message = 'Chưa cấp quyền truy cập Microphone',
    this.isPermanentlyDenied = false,
  ]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Mất kết nối mạng Internet']);
}

class AiExtractionFailure extends Failure {
  const AiExtractionFailure([super.message = 'AI không thể phân tích nội dung biên bản']);
}
