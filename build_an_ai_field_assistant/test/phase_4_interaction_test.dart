import 'package:flutter_test/flutter_test.dart';
import 'package:build_an_ai_field_assistant/features/inspection/domain/entities/inspection_ticket.dart';
import 'package:build_an_ai_field_assistant/features/inspection/data/models/inspection_ticket_model.dart';
import 'package:build_an_ai_field_assistant/features/inspection/data/datasources/inspection_remote_ds.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Giai đoạn 4: UI Interaction & Entity Field Tests', () {
    test('InspectionPart serialization and manipulation', () {
      const part = InspectionPart(name: 'Gioăng chịu dầu DN50', quantity: 2);
      expect(part.name, 'Gioăng chịu dầu DN50');
      expect(part.quantity, 2);

      final updated = part.copyWith(quantity: 3);
      expect(updated.quantity, 3);
      expect(updated.name, 'Gioăng chịu dầu DN50');

      final json = part.toJson();
      expect(json['name'], 'Gioăng chịu dầu DN50');
      expect(json['quantity'], 2);

      final reconstructed = InspectionPart.fromJson(json);
      expect(reconstructed, part);
    });

    test('InspectionTicketModel fromJson parses equipment_id, detected_issues and required_parts', () {
      final jsonMap = {
        'id': 'ticket-001',
        'title': 'Nứt gioăng van PUMP-02',
        'equipment_id': 'PUMP-02',
        'description': 'Van áp lực PUMP-02 bị nứt gioăng dầu tràn sàn.',
        'location': 'Phân xưởng cán thép 2',
        'category': 'mechanical',
        'priority': 'critical',
        'suggested_action': 'Thay thế gioăng DN50 ngay.',
        'detected_issues': [
          'Nứt gioăng mặt bích',
          'Dầu thủy lực tràn sàn',
        ],
        'required_parts': [
          {'name': 'Gioăng cao su DN50', 'quantity': 2},
          {'name': 'Bu-lông M12', 'quantity': 4},
        ],
        'inspector_name': 'Kỹ sư Hoàng',
        'confidence_score': 0.97,
      };

      final ticket = InspectionTicketModel.fromJson(jsonMap);

      expect(ticket.equipmentId, 'PUMP-02');
      expect(ticket.detectedIssues.length, 2);
      expect(ticket.detectedIssues.first, 'Nứt gioăng mặt bích');
      expect(ticket.requiredParts.length, 2);
      expect(ticket.requiredParts[0].name, 'Gioăng cao su DN50');
      expect(ticket.requiredParts[0].quantity, 2);
      expect(ticket.requiredParts[1].quantity, 4);
      expect(ticket.priority, 'critical');
    });

    test('InspectionTicketModel toMap and fromMap preserves Phase 4 fields', () {
      final now = DateTime.now();
      final model = InspectionTicketModel(
        id: 'model-p4',
        title: 'Chập tủ điện ELEC-04',
        equipmentId: 'ELEC-04',
        description: 'Tủ điện phát tia lửa điện và bốc khói.',
        location: 'Kho vật tư',
        category: 'electrical',
        priority: 'critical',
        status: 'pending_sync',
        suggestedAction: 'Cắt cầu dao khẩn cấp',
        detectedIssues: const ['Aptomat quá nhiệt', 'Tia lửa điện lẹt xẹt'],
        requiredParts: const [
          InspectionPart(name: 'Aptomat 100A', quantity: 1),
          InspectionPart(name: 'Đầu cốt đồng', quantity: 3),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final map = model.toMap();
      expect(map['equipment_id'], 'ELEC-04');
      expect(map['detected_issues'], isNotNull);
      expect(map['required_parts'], isNotNull);

      final parsed = InspectionTicketModel.fromMap(map);
      expect(parsed.equipmentId, 'ELEC-04');
      expect(parsed.detectedIssues.length, 2);
      expect(parsed.detectedIssues[0], 'Aptomat quá nhiệt');
      expect(parsed.requiredParts.length, 2);
      expect(parsed.requiredParts[0].name, 'Aptomat 100A');
      expect(parsed.requiredParts[0].quantity, 1);
      expect(parsed.requiredParts[1].quantity, 3);
    });

    test('Offline Smart NLP automatically extracts equipmentId, detectedIssues and requiredParts', () async {
      final remoteDs = InspectionRemoteDataSourceImpl();
      const voiceText = 'Bơm số 2 ký hiệu PUMP-02 bị nứt gioăng dầu rỉ tràn sàn tại Phân xưởng cán thép, cần thay van DN50 và bu lông.';

      final ticket = await remoteDs.extractTicketFromText(text: voiceText);

      expect(ticket.equipmentId, isNotNull);
      expect(ticket.equipmentId!.contains('PUMP-02') || ticket.equipmentId!.contains('PUMP'), true);
      expect(ticket.detectedIssues.isNotEmpty, true);
      expect(ticket.requiredParts.isNotEmpty, true);
      expect(ticket.requiredParts.any((p) => p.name.contains('DN50') || p.name.contains('Bu-lông')), true);
    });
  });
}
