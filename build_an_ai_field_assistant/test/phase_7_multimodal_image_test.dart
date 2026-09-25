import 'package:flutter_test/flutter_test.dart';
import 'package:build_an_ai_field_assistant/features/inspection/data/datasources/inspection_remote_ds.dart';
import 'package:build_an_ai_field_assistant/features/inspection/data/models/inspection_ticket_model.dart';
import 'package:build_an_ai_field_assistant/features/inspection/domain/entities/inspection_ticket.dart';

void main() {
  group('Giai đoạn 1: Multimodal Vision & Image Support Tests', () {
    test('1. InspectionTicket và InspectionTicketModel lưu trữ và copyWith imagePath chuẩn xác', () {
      final now = DateTime.now();
      const testImagePath = '/storage/emulated/0/DCIM/field_valve_crack.jpg';

      final ticket = InspectionTicket(
        id: 'ticket-img-001',
        title: 'Nứt van xả DN50',
        description: 'Vết nứt dọc thân van gây rò rỉ áp suất',
        location: 'Phân xưởng luyện cán 2',
        category: 'mechanical',
        priority: 'high',
        status: 'pending',
        suggestedAction: 'Thay thế van DN50 mới',
        imagePath: testImagePath,
        createdAt: now,
        updatedAt: now,
      );

      expect(ticket.imagePath, equals(testImagePath));

      // Test copyWith
      final updatedTicket = ticket.copyWith(
        imagePath: '/storage/emulated/0/DCIM/field_valve_fixed.jpg',
      );
      expect(updatedTicket.imagePath, equals('/storage/emulated/0/DCIM/field_valve_fixed.jpg'));
      expect(updatedTicket.id, equals(ticket.id));
    });

    test('2. Serialization và Deserialization JSON & SQLite Map bảo toàn trường image_path', () {
      const testImagePath = '/app_images/incident_123.jpg';
      final now = DateTime.now();

      final model = InspectionTicketModel(
        id: 'test-uuid-456',
        title: 'Chập cháy motor máy cắt',
        description: 'Motor bốc khói đen và phát tia lửa điện',
        location: 'Xưởng cơ điện',
        category: 'electrical',
        priority: 'critical',
        status: 'pending',
        suggestedAction: 'Ngắt nguồn và thay motor',
        imagePath: testImagePath,
        createdAt: now,
        updatedAt: now,
      );

      // JSON mapping
      final json = model.toJson();
      expect(json['image_path'], equals(testImagePath));

      final fromJsonModel = InspectionTicketModel.fromJson(json);
      expect(fromJsonModel.imagePath, equals(testImagePath));

      // SQLite Map mapping
      final map = model.toMap();
      expect(map['image_path'], equals(testImagePath));

      final fromMapModel = InspectionTicketModel.fromMap(map);
      expect(fromMapModel.imagePath, equals(testImagePath));
    });

    test('3. Fallback Heuristic bảo toàn imagePath an toàn khi ngoại tuyến hoặc không có API key', () async {
      final remoteDs = InspectionRemoteDataSourceImpl();
      const testImagePath = '/data/user/0/app_recordings/crack_photo.jpg';

      // Call extractTicketMultimodal without API key
      final result = await remoteDs.extractTicketMultimodal(
        userNote: 'Van áp lực PUMP-01 bị rò rỉ dầu tràn sàn',
        imagePath: testImagePath,
        apiKey: '',
      );

      expect(result.imagePath, equals(testImagePath));
      expect(result.equipmentId, equals('PUMP-01'));
      expect(result.category, equals('mechanical'));
      expect(result.priority, equals('high'));
    });

    test('4. extractTicketFromText bảo toàn imagePath khi được truyền vào', () async {
      final remoteDs = InspectionRemoteDataSourceImpl();
      const testImagePath = '/storage/captured_image.png';

      final result = await remoteDs.extractTicketFromText(
        text: 'Aptomat tủ điện tổng quá nhiệt bốc khói nguy hiểm',
        imagePath: testImagePath,
        apiKey: null,
      );

      expect(result.imagePath, equals(testImagePath));
      expect(result.category, equals('electrical'));
      expect(result.priority, equals('critical'));
    });
  });
}
