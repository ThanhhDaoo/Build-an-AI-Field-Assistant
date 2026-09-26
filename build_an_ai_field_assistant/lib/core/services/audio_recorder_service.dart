import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../errors/exceptions.dart';
import '../utils/media_persistence_helper.dart';

/// Supported audio export formats for field recordings
enum AudioOutputFormat {
  m4a,
  wav;

  String get extension => this == AudioOutputFormat.m4a ? 'm4a' : 'wav';

  AudioEncoder get encoder =>
      this == AudioOutputFormat.m4a ? AudioEncoder.aacLc : AudioEncoder.wav;
}

/// Service managing hardware microphone recording, audio pipeline & permissions
class AudioRecorderService {
  final AudioRecorder _audioRecorder;
  Timer? _amplitudeTimer;
  Timer? _durationTimer;

  final _amplitudeController = StreamController<double>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  String? _currentRecordingPath;
  String? _lastRecordedPath;

  AudioRecorderService({AudioRecorder? audioRecorder})
      : _audioRecorder = audioRecorder ?? AudioRecorder();

  bool get isRecording => _isRecording;
  Duration get recordDuration => _recordDuration;
  String? get currentRecordingPath => _currentRecordingPath;
  String? get lastRecordedPath => _lastRecordedPath;

  Stream<double> get amplitudeStream => _amplitudeController.stream;
  Stream<Duration> get durationStream => _durationController.stream;

  /// Check microphone permission with fine-grained status
  Future<bool> hasPermission() async {
    try {
      if (kIsWeb) {
        return await _audioRecorder.hasPermission();
      }

      final status = await Permission.microphone.status;
      if (status.isGranted || status.isLimited) {
        return true;
      }

      final requested = await Permission.microphone.request();
      return requested.isGranted || requested.isLimited;
    } catch (e) {
      debugPrint('Lỗi kiểm tra quyền Micro: $e');
      return false;
    }
  }

  /// Check whether permission was permanently denied by the technician
  Future<bool> isPermanentlyDenied() async {
    if (kIsWeb) return false;
    try {
      return await Permission.microphone.isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  /// Open device settings so user can grant permission manually
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('Không thể mở cài đặt ứng dụng: $e');
      return false;
    }
  }

  /// Generate safe directory & file path in getApplicationDocumentsDirectory
  Future<String> _resolveAudioFilePath(AudioOutputFormat format) async {
    if (kIsWeb) return '';

    final appDocDir = await getApplicationDocumentsDirectory();
    final recordingsDir = io.Directory('${appDocDir.path}/app_recordings');

    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${recordingsDir.path}/field_audio_$timestamp.${format.extension}';
  }

  /// Start voice recording session with specific format (.m4a or .wav)
  Future<void> startRecording({
    AudioOutputFormat format = AudioOutputFormat.m4a,
    String? customPath,
  }) async {
    try {
      final permitted = await hasPermission();
      if (!permitted) {
        final permanentlyDenied = await isPermanentlyDenied();
        throw MicrophonePermissionException(
          permanentlyDenied
              ? 'Quyền truy cập Microphone đã bị từ chối vĩnh viễn. Vui lòng mở Cài đặt ứng dụng để cấp quyền.'
              : 'Ứng dụng cần quyền Microphone để thu âm mô tả sự cố.',
          permanentlyDenied,
        );
      }

      String? targetPath = customPath;
      if (targetPath == null && !kIsWeb) {
        targetPath = await _resolveAudioFilePath(format);
      }
      _currentRecordingPath = targetPath;

      final config = RecordConfig(
        encoder: format.encoder,
        bitRate: format == AudioOutputFormat.m4a ? 128000 : 256000,
        sampleRate: 44100,
      );

      if (kIsWeb) {
        await _audioRecorder.start(config, path: '');
      } else {
        await _audioRecorder.start(config, path: targetPath!);
      }

      _isRecording = true;
      _recordDuration = Duration.zero;
      _durationController.add(_recordDuration);

      // Duration ticker (1s interval)
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordDuration += const Duration(seconds: 1);
        _durationController.add(_recordDuration);
      });

      // Amplitude polling (100ms interval for equalizer waveform)
      _amplitudeTimer?.cancel();
      _amplitudeTimer =
          Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        try {
          if (_isRecording) {
            final amp = await _audioRecorder.getAmplitude();
            // Normalizing dB (-60 to 0) to 0.0 - 1.0 range
            double normalized =
                ((amp.current + 60.0) / 60.0).clamp(0.05, 1.0);
            _amplitudeController.add(normalized);
          }
        } catch (_) {
          _amplitudeController.add(0.08);
        }
      });
    } catch (e) {
      _isRecording = false;
      _cleanupTimers();
      if (e is MicrophonePermissionException) rethrow;
      throw AudioRecordingException('Không thể bắt đầu ghi âm: $e');
    }
  }

  /// Stop voice recording session and return verified file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return _lastRecordedPath;

      final path = await _audioRecorder.stop();
      String? finalPath = path ?? _currentRecordingPath;
      if (finalPath != null && finalPath.isNotEmpty) {
        finalPath = await MediaPersistenceHelper.persistAudio(finalPath);
      }
      _lastRecordedPath = finalPath;
      _isRecording = false;
      _cleanupTimers();

      // Verify file presence on native platforms
      if (!kIsWeb && _lastRecordedPath != null) {
        final file = io.File(_lastRecordedPath!);
        if (await file.exists()) {
          final size = await file.length();
          debugPrint('Đã lưu file âm thanh tại: $_lastRecordedPath ($size bytes)');
        }
      }

      return _lastRecordedPath;
    } catch (e) {
      _cleanupTimers();
      _isRecording = false;
      throw AudioRecordingException('Lỗi khi dừng ghi âm: $e');
    }
  }

  /// Cancel current recording and safely remove intermediate audio file
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
      }

      if (!kIsWeb && _currentRecordingPath != null) {
        final file = io.File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Đã xóa tệp ghi âm bị hủy: $_currentRecordingPath');
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi hủy ghi âm: $e');
    } finally {
      _isRecording = false;
      _currentRecordingPath = null;
      _cleanupTimers();
    }
  }

  /// Delete a saved recording when ticket is deleted or cleaned up
  Future<void> deleteAudioFile(String? filePath) async {
    if (kIsWeb || filePath == null || filePath.isEmpty) return;
    try {
      final file = io.File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Đã xóa tệp âm thanh: $filePath');
      }
    } catch (e) {
      debugPrint('Lỗi xóa tệp âm thanh $filePath: $e');
    }
  }

  void _cleanupTimers() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    _amplitudeController.add(0.0);
  }

  void dispose() {
    _cleanupTimers();
    _amplitudeController.close();
    _durationController.close();
    _audioRecorder.dispose();
  }
}
