import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:build_an_ai_field_assistant/core/errors/exceptions.dart';
import 'package:build_an_ai_field_assistant/core/services/audio_recorder_service.dart';
import 'package:build_an_ai_field_assistant/features/inspection/presentation/widgets/permission_dialog.dart';

import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'create') return null;
        if (methodCall.method == 'hasPermission') return true;
        return null;
      },
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      null,
    );
  });
  group('AudioOutputFormat Tests', () {
    test('Format extensions and encoders are properly mapped', () {
      expect(AudioOutputFormat.m4a.extension, 'm4a');
      expect(AudioOutputFormat.wav.extension, 'wav');
    });
  });

  group('MicrophonePermissionException Tests', () {
    test('Default values and permanently denied flag', () {
      const ex1 = MicrophonePermissionException();
      expect(ex1.isPermanentlyDenied, false);
      expect(ex1.message.contains('Microphone'), true);

      const ex2 = MicrophonePermissionException('Permanently denied', true);
      expect(ex2.isPermanentlyDenied, true);
      expect(ex2.message, 'Permanently denied');
    });
  });

  group('AudioRecorderService Lifecycle State Tests', () {
    test('Initial properties are cleanly reset', () {
      final service = AudioRecorderService();
      expect(service.isRecording, false);
      expect(service.recordDuration, Duration.zero);
      expect(service.currentRecordingPath, isNull);
      expect(service.lastRecordedPath, isNull);
    });
  });

  group('MicrophonePermissionDialog Widget Tests', () {
    testWidgets('Renders permission guidance dialog cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MicrophonePermissionDialog(
              isPermanentlyDenied: true,
            ),
          ),
        ),
      );

      expect(find.text('Cần cấp quyền Microphone'), findsOneWidget);
      expect(find.text('Mở Cài đặt'), findsOneWidget);
      expect(find.text('Để sau'), findsOneWidget);
    });
  });
}
