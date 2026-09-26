import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:build_an_ai_field_assistant/core/utils/media_persistence_helper.dart';
import 'package:build_an_ai_field_assistant/features/inspection/presentation/widgets/inspection_image_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaPersistenceHelper Unit Tests', () {
    test('isDataUri correctly identifies Base64 Data URIs', () {
      expect(MediaPersistenceHelper.isDataUri('data:image/jpeg;base64,abc123=='), isTrue);
      expect(MediaPersistenceHelper.isDataUri('data:audio/mp4;base64,xyz789=='), isTrue);
      expect(MediaPersistenceHelper.isDataUri('blob:http://localhost:8080/123-abc'), isFalse);
      expect(MediaPersistenceHelper.isDataUri('/var/mobile/Containers/Data/1.jpg'), isFalse);
      expect(MediaPersistenceHelper.isDataUri(''), isFalse);
    });

    test('decodeImageBytes and decodeAudioBytes decode valid Base64 payloads', () {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5, 255]);
      final base64String = base64Encode(sampleBytes);
      final dataUri = 'data:image/jpeg;base64,$base64String';

      final decoded = MediaPersistenceHelper.decodeImageBytes(dataUri);
      expect(decoded, isNotNull);
      expect(decoded, equals(sampleBytes));

      final audioUri = 'data:audio/mp4;base64,$base64String';
      final decodedAudio = MediaPersistenceHelper.decodeAudioBytes(audioUri);
      expect(decodedAudio, isNotNull);
      expect(decodedAudio, equals(sampleBytes));
    });

    test('decodeImageBytes returns null for invalid formats gracefully', () {
      expect(MediaPersistenceHelper.decodeImageBytes('not_a_valid_data_uri'), isNull);
      expect(MediaPersistenceHelper.decodeImageBytes('data:image/jpeg;base64,@@@invalid@@@'), isNull);
    });
  });

  group('InspectionImageWidget Widget Tests', () {
    // 1x1 transparent GIF base64
    const transparentGif =
        'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';

    testWidgets('Renders placeholder icon when imagePath is null or empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InspectionImageWidget(imagePath: null),
          ),
        ),
      );

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('Renders Image.memory widget when imagePath is a valid Data URI', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InspectionImageWidget(
              imagePath: transparentGif,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });
}
