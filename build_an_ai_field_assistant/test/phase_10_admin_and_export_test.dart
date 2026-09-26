import 'package:flutter_test/flutter_test.dart';
import 'package:build_an_ai_field_assistant/core/services/report_export_service.dart';
import 'package:build_an_ai_field_assistant/features/inspection/domain/entities/inspection_ticket.dart';
import 'package:build_an_ai_field_assistant/features/inspection/data/models/inspection_ticket_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleTicket = InspectionTicket(
    id: 'test-admin-01',
    title: 'Rò rỉ dầu van thủy lực DN50',
    description: 'Áp suất giảm đột ngột tại cụm van chính.',
    location: 'Xưởng Cán 2 - Tầng 1',
    category: 'mechanical',
    priority: 'critical',
    status: 'synced',
    suggestedAction: 'Thay thế gioăng phớt cao su',
    inspectorName: 'Kỹ sư Hoàng Nam',
    confidenceScore: 0.98,
    equipmentId: 'VALVE-DN50',
    detectedIssues: const ['Rò rỉ áp suất', 'Nhiệt độ dầu 65C'],
    requiredParts: const [InspectionPart(name: 'Gioăng DN50', quantity: 2)],
    operationalStatus: 'in_progress',
    assignedTo: 'Kỹ sư Vũ Thành',
    managerNotes: 'Ưu tiên xử lý gấp trước giờ chuyển ca.',
    resolvedAt: null,
    createdAt: DateTime(2026, 9, 26, 14, 30),
    updatedAt: DateTime(2026, 9, 26, 15, 0),
  );

  group('Operational Lifecycle & Entity Tests', () {
    test('InspectionTicket operational status getters identify states properly', () {
      expect(sampleTicket.isPendingReview, isFalse);
      expect(sampleTicket.isInProgress, isTrue);
      expect(sampleTicket.isResolved, isFalse);

      final pendingTicket = sampleTicket.copyWith(operationalStatus: 'pending_review');
      expect(pendingTicket.isPendingReview, isTrue);
      expect(pendingTicket.isInProgress, isFalse);

      final resolvedTicket = sampleTicket.copyWith(operationalStatus: 'resolved');
      expect(resolvedTicket.isResolved, isTrue);

      final closedTicket = sampleTicket.copyWith(operationalStatus: 'closed');
      expect(closedTicket.isResolved, isTrue);
    });

    test('InspectionTicketModel serialization preserves operational fields', () {
      final model = InspectionTicketModel.fromEntity(sampleTicket);

      // 1. To JSON and from JSON
      final json = model.toJson();
      expect(json['operational_status'], equals('in_progress'));
      expect(json['assigned_to'], equals('Kỹ sư Vũ Thành'));
      expect(json['manager_notes'], equals('Ưu tiên xử lý gấp trước giờ chuyển ca.'));

      final fromJson = InspectionTicketModel.fromJson(json);
      expect(fromJson.operationalStatus, equals('in_progress'));
      expect(fromJson.assignedTo, equals('Kỹ sư Vũ Thành'));
      expect(fromJson.managerNotes, equals('Ưu tiên xử lý gấp trước giờ chuyển ca.'));

      // 2. To SQLite Map and from SQLite Map
      final map = model.toMap();
      expect(map['operational_status'], equals('in_progress'));
      expect(map['assigned_to'], equals('Kỹ sư Vũ Thành'));
      expect(map['manager_notes'], equals('Ưu tiên xử lý gấp trước giờ chuyển ca.'));

      final fromMap = InspectionTicketModel.fromMap(map);
      expect(fromMap.operationalStatus, equals('in_progress'));
      expect(fromMap.assignedTo, equals('Kỹ sư Vũ Thành'));
      expect(fromMap.managerNotes, equals('Ưu tiên xử lý gấp trước giờ chuyển ca.'));
    });
  });

  group('ReportExportService CSV Generation Tests', () {
    test('generateTicketsCsv outputs UTF-8 BOM, headers, and correctly mapped columns', () {
      final csv = ReportExportService.generateTicketsCsv([sampleTicket]);

      // 1. Checks UTF-8 BOM at the very beginning
      expect(csv.startsWith('\uFEFF'), isTrue);

      // 2. Checks Vietnamese headers
      expect(csv.contains('Mã phiếu,Tiêu đề sự cố,Mã thiết bị,Vị trí hiện trường'), isTrue);

      // 3. Checks data row content and translations
      expect(csv.contains('test-admin-01'), isTrue);
      expect(csv.contains('VALVE-DN50'), isTrue);
      expect(csv.contains('Khẩn cấp'), isTrue); // Critical -> Khẩn cấp
      expect(csv.contains('Cơ khí'), isTrue); // Mechanical -> Cơ khí
      expect(csv.contains('Đang xử lý'), isTrue); // in_progress -> Đang xử lý
      expect(csv.contains('Kỹ sư Vũ Thành'), isTrue);
      expect(csv.contains('Gioăng DN50 (x2)'), isTrue);
    });

    test('generateTicketsCsv properly escapes commas and double quotes', () {
      final ticketWithSpecialChars = sampleTicket.copyWith(
        id: 'special-char-01',
        title: 'Lỗi "nghiêm trọng", cần thay gấp',
        description: 'Mô tả có dấu phẩy, và dấu "ngoặc kép".',
      );

      final csv = ReportExportService.generateTicketsCsv([ticketWithSpecialChars]);
      expect(csv.contains('"Lỗi ""nghiêm trọng"", cần thay gấp"'), isTrue);
    });
  });
}
