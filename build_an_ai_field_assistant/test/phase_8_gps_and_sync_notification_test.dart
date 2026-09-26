import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:build_an_ai_field_assistant/core/services/location_service.dart';
import 'package:build_an_ai_field_assistant/core/services/sync_notification_service.dart';
import 'package:build_an_ai_field_assistant/core/services/audio_recorder_service.dart';
import 'package:build_an_ai_field_assistant/core/services/connectivity_service.dart';
import 'package:build_an_ai_field_assistant/features/inspection/domain/entities/inspection_ticket.dart';
import 'package:build_an_ai_field_assistant/features/inspection/domain/repositories/i_inspection_repository.dart';
import 'package:build_an_ai_field_assistant/features/inspection/presentation/controllers/inspection_controller.dart';

class MockInspectionRepository implements IInspectionRepository {
  List<InspectionTicket> tickets = [];

  @override
  Future<void> deleteTicket(String id) async {
    tickets.removeWhere((t) => t.id == id);
  }

  @override
  Future<InspectionTicket> extractTicketFromText(
    String text, {
    String? audioPath,
    String? imagePath,
  }) async {
    return InspectionTicket(
      id: 'test-ticket-id',
      title: 'Động cơ quá nhiệt',
      equipmentId: 'MOTOR-01',
      category: 'Cơ khí',
      priority: 'high',
      location: 'Phân xưởng 1',
      description: text,
      suggestedAction: 'Kiểm tra vòng bi',
      detectedIssues: const ['Quá nhiệt'],
      requiredParts: const [],
      imagePath: imagePath,
      inspectorName: 'Kỹ sư test',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: 'pending',
    );
  }

  @override
  Future<InspectionTicket> extractTicketFromVoice({
    required String audioPath,
    String? audioTranscript,
    String? imagePath,
  }) async {
    return extractTicketFromText(
      audioTranscript ?? 'Sự cố kiểm tra giọng nói',
      audioPath: audioPath,
      imagePath: imagePath,
    );
  }

  @override
  Future<InspectionTicket> extractTicketMultimodal({
    String? audioPath,
    String? audioTranscript,
    String? imagePath,
    String? textNotes,
  }) async {
    return extractTicketFromText(
      audioTranscript ?? textNotes ?? '',
      audioPath: audioPath,
      imagePath: imagePath,
    );
  }

  @override
  Future<List<InspectionTicket>> getTickets() async => tickets;

  @override
  Future<InspectionTicket> saveTicket(InspectionTicket ticket) async {
    tickets.add(ticket);
    return ticket;
  }

  @override
  Future<InspectionTicket?> updateTicketOperationalStatus(
    String ticketId,
    String operationalStatus, {
    String? assignedTo,
    String? managerNotes,
  }) async {
    final index = tickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) return null;
    final updated = tickets[index].copyWith(
      operationalStatus: operationalStatus,
      assignedTo: assignedTo,
      managerNotes: managerNotes,
    );
    tickets[index] = updated;
    return updated;
  }

  @override
  Future<int> syncPendingTickets() async {
    final pending = tickets.where((t) => t.isPendingSync).length;
    tickets = tickets.map((t) => t.copyWith(status: 'synced')).toList();
    return pending;
  }

  @override
  Stream<List<InspectionTicket>> watchTickets() async* {
    yield tickets;
  }
}

class FakeConnectivityService extends ConnectivityService {
  FakeConnectivityService() : super(autoInit: false);

  @override
  bool get isOnline => true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class FakeAudioRecorderService extends Fake implements AudioRecorderService {
  @override
  Stream<double> get amplitudeStream => const Stream.empty();

  @override
  Stream<Duration> get durationStream => const Stream.empty();

  @override
  bool get isRecording => false;

  @override
  Duration get recordDuration => Duration.zero;

  @override
  Future<void> cancelRecording() async {}

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Giai đoạn 2: GPS Location & Sync Notification Unit Tests', () {
    test('1. LocationService.formatCoordinates định dạng chuẩn tọa độ GPS Bắc/Nam - Đông/Tây', () {
      // Tọa độ tại TP. Hồ Chí Minh
      final hcmc = LocationService.formatCoordinates(10.7769, 106.7009);
      expect(hcmc, equals('10.7769° N, 106.7009° E (Vị trí GPS)'));

      // Tọa độ Nam bán cầu & Tây bán cầu
      final rio = LocationService.formatCoordinates(-22.9068, -43.1729);
      expect(rio, equals('22.9068° S, 43.1729° W (Vị trí GPS)'));

      // Tọa độ Bắc bán cầu & Tây bán cầu (New York)
      final ny = LocationService.formatCoordinates(40.7128, -74.0060);
      expect(ny, equals('40.7128° N, 74.0060° W (Vị trí GPS)'));
    });

    test('2. LocationService.getCurrentFormattedLocation trả về chuỗi vị trí khi có tọa độ', () async {
      final mockPos = Position(
        longitude: 106.7009,
        latitude: 10.7769,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );

      final service = LocationService(mockPositionProvider: () async => mockPos);
      final formatted = await service.getCurrentFormattedLocation();

      expect(formatted, isNotNull);
      expect(formatted, contains('10.7769° N'));
      expect(formatted, contains('106.7009° E'));
      expect(formatted, contains('(Vị trí GPS)'));
    });

    test('3. LocationService.getCurrentFormattedLocation trả về null khi không lấy được tọa độ', () async {
      final service = LocationService(mockPositionProvider: () async => null);
      final formatted = await service.getCurrentFormattedLocation();

      expect(formatted, isNull);
    });

    test('4. SyncNotificationService phát thông báo chính xác khi hoàn tất đồng bộ', () async {
      final syncService = SyncNotificationService();

      SyncNotificationEvent? receivedEvent;
      final sub = syncService.onSyncNotification.listen((event) {
        receivedEvent = event;
      });

      syncService.notifySyncSuccess(5);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedEvent, isNotNull);
      expect(receivedEvent!.syncedCount, equals(5));
      expect(
        receivedEvent!.message,
        equals('✓ Đã tự động đồng bộ thành công 5 phiếu kiểm tra lên máy chủ!'),
      );
      expect(syncService.lastEvent, equals(receivedEvent));

      syncService.clearLastEvent();
      expect(syncService.lastEvent, isNull);

      await sub.cancel();
      syncService.dispose();
    });

    test('5. InspectionController tích hợp 1-chạm GPS và tự động gắn GPS vào biên bản', () async {
      final mockPos = Position(
        longitude: 105.8342,
        latitude: 21.0278,
        timestamp: DateTime.now(),
        accuracy: 3.0,
        altitude: 5.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );

      final locationService = LocationService(mockPositionProvider: () async => mockPos);
      final syncService = SyncNotificationService();
      final repo = MockInspectionRepository();
      final connectivity = FakeConnectivityService();
      final audioRecorder = FakeAudioRecorderService();

      final controller = InspectionController(
        repository: repo,
        audioRecorderService: audioRecorder,
        connectivityService: connectivity,
        locationService: locationService,
        syncNotificationService: syncService,
      );

      // 1. Thao tác 1-chạm lấy tọa độ GPS
      final gpsResult = await controller.fetchGpsLocation();
      expect(gpsResult, isNotNull);
      expect(controller.taggedGpsLocation, equals('21.0278° N, 105.8342° E (Vị trí GPS)'));

      // 2. Trích xuất biên bản tự động gắn tọa độ GPS vào trường location
      final draftTicket = await controller.extractFromText('Sự cố hỏng bơm làm mát');
      expect(draftTicket, isNotNull);
      expect(draftTicket!.location, contains('21.0278° N, 105.8342° E (Vị trí GPS)'));

      // 3. Phản hồi thông báo đồng bộ ngầm
      syncService.notifySyncSuccess(2);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.activeSyncMessage, contains('Đã tự động đồng bộ thành công 2 phiếu'));

      // 4. Dismiss banner thông báo
      controller.dismissSyncMessage();
      expect(controller.activeSyncMessage, isNull);

      controller.dispose();
      syncService.dispose();
      audioRecorder.dispose();
    });
  });
}
