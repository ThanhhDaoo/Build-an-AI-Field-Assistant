import 'package:flutter_test/flutter_test.dart';
import 'package:build_an_ai_field_assistant/features/inspection/domain/entities/inspection_ticket.dart';
import 'package:build_an_ai_field_assistant/features/inspection/data/models/inspection_ticket_model.dart';

void main() {
  test('InspectionTicket creation test', () {
    final now = DateTime.now();
    final ticket = InspectionTicket(
      id: 'test-123',
      title: 'Kiểm tra van điều áp',
      description: 'Mô tả chi tiết sự cố rò rỉ',
      location: 'Phân xưởng cán thép số 2',
      category: 'mechanical',
      priority: 'high',
      status: 'pending_sync',
      suggestedAction: 'Thay van DN50',
      createdAt: now,
      updatedAt: now,
    );

    expect(ticket.id, 'test-123');
    expect(ticket.isPendingSync, true);
    expect(ticket.isSynced, false);
    expect(ticket.priority, 'high');
  });

  test('InspectionTicketModel fromMap and toMap test', () {
    final now = DateTime.now();
    final model = InspectionTicketModel(
      id: 'model-456',
      title: 'Động cơ quá nhiệt',
      description: 'Nhiệt độ đạt 95 độ C',
      location: 'Trạm bơm P-102',
      category: 'mechanical',
      priority: 'critical',
      status: 'pending_sync',
      suggestedAction: 'Dừng bơm để kiểm tra làm mát',
      createdAt: now,
      updatedAt: now,
    );

    final map = model.toMap();
    expect(map['id'], 'model-456');
    expect(map['priority'], 'critical');

    final reconstructed = InspectionTicketModel.fromMap(map);
    expect(reconstructed.id, model.id);
    expect(reconstructed.title, model.title);
    expect(reconstructed.priority, model.priority);
  });
}
