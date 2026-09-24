import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../errors/exceptions.dart';

/// Service managing hardware microphone recording & real-time amplitude stream
class AudioRecorderService {
  final AudioRecorder _audioRecorder;
  Timer? _amplitudeTimer;
  Timer? _durationTimer;
  
  final _amplitudeController = StreamController<double>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  String? _lastRecordedPath;

  AudioRecorderService({AudioRecorder? audioRecorder})
      : _audioRecorder = audioRecorder ?? AudioRecorder();

  bool get isRecording => _isRecording;
  Duration get recordDuration => _recordDuration;
  String? get lastRecordedPath => _lastRecordedPath;

  Stream<double> get amplitudeStream => _amplitudeController.stream;
  Stream<Duration> get durationStream => _durationController.stream;

  /// Check & request microphone permission
  Future<bool> hasPermission() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      debugPrint('Error checking mic permission: $e');
      return false;
    }
  }

  /// Start voice recording session
  Future<void> startRecording({String? customPath}) async {
    try {
      final hasPerm = await hasPermission();
      if (!hasPerm) {
        throw const AudioRecordingException('Không có quyền sử dụng Microphone.');
      }

      String? filePath = customPath;
      if (filePath == null && !kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath = '${tempDir.path}/field_audio_$timestamp.m4a';
      }

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      if (kIsWeb) {
        // On web, record directly without file path
        await _audioRecorder.start(config, path: '');
      } else {
        await _audioRecorder.start(config, path: filePath!);
      }

      _isRecording = true;
      _recordDuration = Duration.zero;
      _durationController.add(_recordDuration);

      // Start duration ticker
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordDuration += const Duration(seconds: 1);
        _durationController.add(_recordDuration);
      });

      // Start amplitude polling for waveform
      _amplitudeTimer?.cancel();
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        try {
          if (_isRecording) {
            final amp = await _audioRecorder.getAmplitude();
            // Amplitude current is usually in dB (-60 to 0)
            // Normalize to 0.0 - 1.0 range
            double normalized = ((amp.current + 60.0) / 60.0).clamp(0.05, 1.0);
            _amplitudeController.add(normalized);
          }
        } catch (_) {
          _amplitudeController.add(0.1);
        }
      });
    } catch (e) {
      _isRecording = false;
      _cleanupTimers();
      if (e is AudioRecordingException) rethrow;
      throw AudioRecordingException('Lỗi bắt đầu ghi âm: $e');
    }
  }

  /// Stop voice recording and return saved file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return _lastRecordedPath;

      final path = await _audioRecorder.stop();
      _lastRecordedPath = path;
      _isRecording = false;
      _cleanupTimers();
      return path;
    } catch (e) {
      _cleanupTimers();
      _isRecording = false;
      throw AudioRecordingException('Lỗi dừng ghi âm: $e');
    }
  }

  /// Cancel and discard current recording
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
      }
    } catch (_) {
    } finally {
      _isRecording = false;
      _cleanupTimers();
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
