import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Professional Service managing device Speech-to-Text (STT) for live transcription
class SpeechToTextService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';

  final _textController = StreamController<String>.broadcast();
  Stream<String> get textStream => _textController.stream;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isAvailable => _speechToText.isAvailable;
  String get lastWords => _lastWords;

  /// Initialize speech recognition with device locale
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (val) {
          debugPrint('STT Error: [${val.errorMsg}] - permanent: ${val.permanent}');
        },
        onStatus: (status) {
          _isListening = _speechToText.isListening;
          debugPrint('STT Status changed: $status');
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Không thể khởi tạo SpeechToText: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Start live transcription with Vietnamese locale priority
  Future<void> startListening({Function(String words)? onResult}) async {
    _lastWords = '';
    final hasInit = await initialize();
    if (!hasInit) {
      debugPrint('SpeechToText is not initialized or not supported on this platform/device.');
      return;
    }

    try {
      // Find Vietnamese locale or fallback to device default
      final locales = await _speechToText.locales();
      final viLocale = locales.firstWhere(
        (l) => l.localeId.toLowerCase().startsWith('vi'),
        orElse: () => locales.isNotEmpty
            ? locales.first
            : LocaleName('vi_VN', 'Tiếng Việt'),
      );

      debugPrint('Using STT locale: ${viLocale.localeId} (${viLocale.name})');

      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _lastWords = result.recognizedWords;
          _textController.add(_lastWords);
          onResult?.call(_lastWords);
        },
        listenOptions: SpeechListenOptions(
          localeId: viLocale.localeId,
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          autoPunctuation: true,
        ),
      );
      _isListening = true;
    } catch (e) {
      debugPrint('Lỗi startListening STT: $e');
    }
  }

  /// Stop live transcription and return captured text
  Future<String> stopListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (e) {
      debugPrint('Lỗi stopListening STT: $e');
    } finally {
      _isListening = false;
    }
    return _lastWords.trim();
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    try {
      await _speechToText.cancel();
    } catch (_) {
    } finally {
      _isListening = false;
      _lastWords = '';
    }
  }

  void dispose() {
    _textController.close();
  }
}
