import 'package:flutter_test/flutter_test.dart';
import 'package:build_an_ai_field_assistant/features/inspection/domain/entities/inspection_ticket.dart';

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
}
