import 'package:flutter_test/flutter_test.dart';
import 'package:build_an_ai_field_assistant/core/services/speech_to_text_service.dart';

void main() {
  group('SpeechToTextService Unit Tests', () {
    late SpeechToTextService service;

    setUp(() {
      service = SpeechToTextService();
    });

    tearDown(() {
      service.dispose();
    });

    test('Initial properties are correctly configured', () {
      expect(service.isListening, false);
      expect(service.lastWords, '');
    });

    test('Cancel listening resets states cleanly', () async {
      await service.cancelListening();
      expect(service.isListening, false);
      expect(service.lastWords, '');
    });

    test('TextStream is active and broadcast', () {
      expect(service.textStream, isNotNull);
      expect(service.textStream.isBroadcast, true);
    });
  });
}
