import 'dart:async';
import 'dart:io' as io;
import 'package:flutter_test/flutter_test.dart';
import 'package:build_an_ai_field_assistant/core/errors/exceptions.dart';
import 'package:build_an_ai_field_assistant/core/services/connectivity_service.dart';
import 'package:build_an_ai_field_assistant/features/inspection/data/datasources/inspection_local_ds.dart';
import 'package:build_an_ai_field_assistant/features/inspection/data/datasources/inspection_remote_ds.dart';
import 'package:build_an_ai_field_assistant/features/inspection/data/models/inspection_ticket_model.dart';
import 'package:build_an_ai_field_assistant/features/inspection/data/repositories/inspection_repository_impl.dart';
import 'package:build_an_ai_field_assistant/features/inspection/domain/entities/inspection_ticket.dart';

class MockRemoteDataSource implements IInspectionRemoteDataSource {
  bool shouldSucceed = true;
  bool throwException = false;
  final List<InspectionTicketModel> syncedTickets = [];

  @override
  Future<bool> syncTicketToRemote(InspectionTicketModel ticket) async {
    if (throwException) {
      throw const ServerException('503 Service Unavailable');
    }
    if (shouldSucceed) {
      syncedTickets.add(ticket);
      return true;
    }
    return false;
  }

  @override
  Future<InspectionTicketModel> extractTicketFromAudio({
    io.File? audioFile,
    String? audioPath,
    String? apiKey,
    String? userNote,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<InspectionTicketModel> extractTicketFromAudioFile(
    io.File audioFile, {
    String? apiKey,
    String? userNote,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<InspectionTicketModel> extractTicketFromText({
    required String text,
    String? apiKey,
    String? audioPath,
    String? imagePath,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<InspectionTicketModel> extractTicketMultimodal({
    io.File? audioFile,
    String? audioPath,
    io.File? imageFile,
    String? imagePath,
    String? apiKey,
    String? userNote,
  }) async {
    throw UnimplementedError();
  }
}

class MockLocalDataSource implements IInspectionLocalDataSource {
  final List<InspectionTicketModel> storage = [];

  @override
  Future<List<InspectionTicketModel>> getTickets() async {
    return List.from(storage);
  }

  @override
  Future<List<InspectionTicketModel>> getPendingTickets() async {
    return storage
        .where((t) => t.status == 'pending' || t.status == 'pending_sync')
        .toList();
  }

  @override
  Future<void> saveTicket(InspectionTicketModel ticket) async {
    final idx = storage.indexWhere((t) => t.id == ticket.id);
    if (idx != -1) {
      storage[idx] = ticket;
    } else {
      storage.insert(0, ticket);
    }
  }

  @override
  Future<void> markTicketAsSynced(String id) async {
    final idx = storage.indexWhere((t) => t.id == id);
    if (idx != -1) {
      storage[idx] = InspectionTicketModel.fromEntity(
        storage[idx].copyWith(
          status: 'synced',
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<void> deleteTicket(String id) async {
    storage.removeWhere((t) => t.id == id);
  }
}

class FakeConnectivityService extends ConnectivityService {
  bool _mockOnline;
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  FakeConnectivityService({bool initialOnline = true})
      : _mockOnline = initialOnline,
        super(autoInit: false);

  @override
  bool get isOnline => _mockOnline;

  @override
  Stream<bool> get onConnectivityChanged => _statusController.stream;

  void setOnline(bool online) {
    _mockOnline = online;
    _statusController.add(online);
  }

  @override
  void dispose() {
    _statusController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Giai đoạn 5: Offline-First & Đồng bộ Dữ liệu Tests', () {
    late MockRemoteDataSource remoteDS;
    late MockLocalDataSource localDS;
    late FakeConnectivityService connectivityService;
    late InspectionRepositoryImpl repository;

    final now = DateTime.now();

    final testTicket = InspectionTicket(
      id: 'test-ticket-01',
      title: 'Rò rỉ khí nén tháp làm mát B',
      description: 'Đường ống áp lực cao bị xì hơi, gioăng làm kín rách.',
      location: 'Tháp giải nhiệt B',
      category: 'mechanical',
      priority: 'high',
      status: 'pending',
      suggestedAction: 'Siết lại bu-lông và thay thế gioăng DN50',
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      remoteDS = MockRemoteDataSource();
      localDS = MockLocalDataSource();
      connectivityService = FakeConnectivityService(initialOnline: true);
      repository = InspectionRepositoryImpl(
        remoteDataSource: remoteDS,
        localDataSource: localDS,
        connectivityService: connectivityService,
      );
    });

    tearDown(() {
      repository.dispose();
      connectivityService.dispose();
    });

    test('1. Entity & Model status mapping correctly identifies isSynced and isPendingSync', () {
      final syncedTicket = testTicket.copyWith(status: 'synced');
      final pendingTicket = testTicket.copyWith(status: 'pending');
      final legacyPending = testTicket.copyWith(status: 'pending_sync');

      expect(syncedTicket.isSynced, isTrue);
      expect(syncedTicket.isPendingSync, isFalse);

      expect(pendingTicket.isSynced, isFalse);
      expect(pendingTicket.isPendingSync, isTrue);

      expect(legacyPending.isSynced, isFalse);
      expect(legacyPending.isPendingSync, isTrue);
    });

    test('2. Khi có mạng (Online): Gửi phiếu lên server và cập nhật trạng thái synced', () async {
      connectivityService.setOnline(true);
      remoteDS.shouldSucceed = true;

      final result = await repository.saveTicket(testTicket);

      expect(result.status, 'synced');
      expect(result.isSynced, isTrue);
      expect(remoteDS.syncedTickets.length, 1);
      expect(remoteDS.syncedTickets.first.id, testTicket.id);

      final localTickets = await localDS.getTickets();
      expect(localTickets.length, 1);
      expect(localTickets.first.status, 'synced');
    });

    test('3. Khi mất mạng (Offline): Lưu phiếu vào local database với trạng thái pending', () async {
      connectivityService.setOnline(false);

      final result = await repository.saveTicket(testTicket);

      expect(result.status, 'pending');
      expect(result.isPendingSync, isTrue);
      expect(remoteDS.syncedTickets.isEmpty, isTrue);

      final pendingList = await localDS.getPendingTickets();
      expect(pendingList.length, 1);
      expect(pendingList.first.id, testTicket.id);
      expect(pendingList.first.status, 'pending');
    });

    test('4. Khi có mạng nhưng Server trả lỗi: Tự động fallback lưu local với trạng thái pending', () async {
      connectivityService.setOnline(true);
      remoteDS.throwException = true; // Giả lập server lỗi 503

      final result = await repository.saveTicket(testTicket);

      // Phải an toàn, không được crash và lưu thành pending
      expect(result.status, 'pending');
      expect(result.isPendingSync, isTrue);

      final pendingList = await localDS.getPendingTickets();
      expect(pendingList.length, 1);
      expect(pendingList.first.status, 'pending');
    });

    test('5. Tự động đồng bộ các bản ghi pending khi phát hiện có mạng trở lại (ConnectivityService)', () async {
      // 1. Ban đầu ngoại tuyến: Lưu 2 phiếu pending vào local DB
      connectivityService.setOnline(false);
      final ticket1 = testTicket.copyWith(id: 'offline-01');
      final ticket2 = testTicket.copyWith(id: 'offline-02');

      await repository.saveTicket(ticket1);
      await repository.saveTicket(ticket2);

      var pending = await localDS.getPendingTickets();
      expect(pending.length, 2);

      // 2. Mạng được phục hồi: phát tín hiệu isOnline = true qua ConnectivityService
      remoteDS.shouldSucceed = true;
      remoteDS.throwException = false;
      connectivityService.setOnline(true);

      // Chờ microtask để auto-sync xử lý
      await Future.delayed(const Duration(milliseconds: 50));

      // 3. Toàn bộ 2 phiếu pending đã được tự động gửi và đánh dấu 'synced'
      final remainingPending = await localDS.getPendingTickets();
      expect(remainingPending.length, 0);

      final allTickets = await localDS.getTickets();
      expect(allTickets.every((t) => t.status == 'synced'), isTrue);
      expect(remoteDS.syncedTickets.length, 2);
    });

    test('6. syncPendingTickets() thủ công duyệt qua danh sách và trả về số lượng đồng bộ thành công', () async {
      connectivityService.setOnline(false);
      await repository.saveTicket(testTicket.copyWith(id: 'sync-manual-01'));
      await repository.saveTicket(testTicket.copyWith(id: 'sync-manual-02'));

      // Chuyển sang online nhưng không kích hoạt event listener
      connectivityService._mockOnline = true;
      remoteDS.shouldSucceed = true;

      final count = await repository.syncPendingTickets();
      expect(count, 2);

      final pending = await localDS.getPendingTickets();
      expect(pending.isEmpty, isTrue);
    });
  });
}
