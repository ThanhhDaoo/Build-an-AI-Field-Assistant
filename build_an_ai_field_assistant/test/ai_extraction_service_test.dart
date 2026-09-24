import 'package:flutter_test/flutter_test.dart';
import 'package:build_an_ai_field_assistant/features/inspection/data/models/inspection_ticket_model.dart';
import 'package:build_an_ai_field_assistant/features/inspection/data/datasources/inspection_remote_ds.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Giai đoạn 3: AI Service & Structured Output Tests', () {
    late InspectionRemoteDataSourceImpl remoteDataSource;

    setUp(() {
      remoteDataSource = InspectionRemoteDataSourceImpl();
    });

    test('InspectionTicketModel.fromJson validates and parses clean JSON properly', () {
      final jsonMap = {
        'title': 'Rò rỉ van dầu thủy lực',
        'description': 'Van dầu DN50 bị rò rỉ tràn sàn nguy hiểm.',
        'location': 'Phân xưởng cán thép 2',
        'category': 'MECHANICAL',
        'priority': 'HIGH',
        'suggested_action': 'Thay gioăng và van DN50 mới.',
        'inspector_name': 'Kỹ sư Tuấn',
        'confidence_score': 0.95,
        'raw_transcript': 'Phát hiện van dầu DN50 bị rò rỉ tràn sàn tại Phân xưởng cán thép 2.',
      };

      final ticket = InspectionTicketModel.fromJson(
        jsonMap,
        audioPath: '/mock/path/audio.m4a',
      );

      expect(ticket.title, 'Rò rỉ van dầu thủy lực');
      expect(ticket.location, 'Phân xưởng cán thép 2');
      expect(ticket.category, 'mechanical'); // Normalized to lowercase
      expect(ticket.priority, 'high'); // Normalized to lowercase
      expect(ticket.inspectorName, 'Kỹ sư Tuấn');
      expect(ticket.confidenceScore, 0.95);
      expect(ticket.audioPath, '/mock/path/audio.m4a');
      expect(ticket.id.isNotEmpty, true);
      expect(ticket.createdAt, isNotNull);
    });

    test('InspectionTicketModel.fromJson handles missing optional fields safely', () {
      final jsonMap = <String, dynamic>{
        'title': 'Sự cố thiết bị',
      };

      final ticket = InspectionTicketModel.fromJson(jsonMap);

      expect(ticket.title, 'Sự cố thiết bị');
      expect(ticket.category, 'general');
      expect(ticket.priority, 'medium');
      expect(ticket.inspectorName, 'Kỹ sư hiện trường');
      expect(ticket.status, 'pending');
      expect(ticket.isPendingSync, true);
      expect(ticket.id.isNotEmpty, true);
    });

    test('Offline Smart NLP Fallback correctly categorizes mechanical issue', () async {
      const speech = 'Phát hiện van áp lực và puly máy bơm số 2 bị kẹt bạc đạn kêu to tại phân xưởng 3, cần xử lý gấp.';
      final ticket = await remoteDataSource.extractTicketFromText(text: speech);

      expect(ticket.category, 'mechanical');
      expect(ticket.priority, 'high');
      expect(ticket.rawTranscript, speech);
      expect(ticket.title.contains('van') || ticket.title.contains('Phát hiện'), true);
    });

    test('Offline Smart NLP Fallback correctly categorizes critical electrical issue', () async {
      const speech = 'Khẩn cấp! Tủ điện tổng đang bốc khói có tia lửa điện chập cháy aptomat, ngắt cầu dao ngay.';
      final ticket = await remoteDataSource.extractTicketFromText(text: speech);

      expect(ticket.category, 'electrical');
      expect(ticket.priority, 'critical');
    });

    test('Offline Smart NLP Fallback correctly categorizes civil structure issue', () async {
      const speech = 'Phát hiện nứt dầm bê tông cốt thép tại tầng 3 block B chiều dài 2 mét.';
      final ticket = await remoteDataSource.extractTicketFromText(text: speech);

      expect(ticket.category, 'civil');
      expect(ticket.location.contains('tầng 3') || ticket.location.contains('block'), true);
    });

    test('Offline Smart NLP Fallback correctly categorizes safety and hvac issues', () async {
      const speechSafety = 'Tràn dầu trơn trượt mất an toàn lao động cạnh bình cứu hỏa pccc.';
      final ticketSafety = await remoteDataSource.extractTicketFromText(text: speechSafety);
      expect(ticketSafety.category, 'safety');

      const speechHvac = 'Hệ thống chiller tháp giải nhiệt làm mát phòng máy bị quá nhiệt.';
      final ticketHvac = await remoteDataSource.extractTicketFromText(text: speechHvac);
      expect(ticketHvac.category, 'hvac');
    });

    test('Fallback audio extraction handles empty voice safely without crash', () async {
      final ticket = await remoteDataSource.extractTicketFromAudio(
        audioPath: '/mock/path/field_audio.m4a',
      );

      expect(ticket.title.contains('Biên bản ghi âm hiện trường'), true);
      expect(ticket.category, 'general');
      expect(ticket.audioPath, '/mock/path/field_audio.m4a');
      expect(ticket.id.isNotEmpty, true);
    });
  });
}
