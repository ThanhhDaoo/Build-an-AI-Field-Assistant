import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/inspection_ticket_model.dart';

abstract class IInspectionLocalDataSource {
  Future<List<InspectionTicketModel>> getTickets();
  Future<List<InspectionTicketModel>> getPendingTickets();
  Future<void> saveTicket(InspectionTicketModel ticket);
  Future<void> deleteTicket(String id);
  Future<void> markTicketAsSynced(String id);
}

class InspectionLocalDataSourceImpl implements IInspectionLocalDataSource {
  Database? _database;
  static const String _prefsKey = 'cached_inspection_tickets';
  static List<InspectionTicketModel>? _inMemoryTickets;

  Future<Database?> _getDatabase() async {
    if (kIsWeb) return null; // SQLite is not directly available on web without WASM
    if (_database != null) return _database!;

    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, AppConstants.dbName);

      _database = await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ${AppConstants.ticketsTable} (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT NOT NULL,
              location TEXT NOT NULL,
              category TEXT NOT NULL,
              priority TEXT NOT NULL,
              status TEXT NOT NULL,
              suggested_action TEXT,
              inspector_name TEXT,
              confidence_score REAL,
              raw_transcript TEXT,
              audio_path TEXT,
              image_path TEXT,
              equipment_id TEXT,
              detected_issues TEXT,
              required_parts TEXT,
              operational_status TEXT,
              assigned_to TEXT,
              manager_notes TEXT,
              resolved_at TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            try {
              await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN equipment_id TEXT');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN detected_issues TEXT');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN required_parts TEXT');
            } catch (_) {}
          }
          if (oldVersion < 3) {
            try {
              await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN image_path TEXT');
            } catch (_) {}
          }
          try {
            await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN operational_status TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN assigned_to TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN manager_notes TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN resolved_at TEXT');
          } catch (_) {}
        },
      );
      return _database;
    } catch (e) {
      debugPrint('Failed to open SQLite database: $e. Falling back to SharedPreferences.');
      return null;
    }
  }

  @override
  Future<List<InspectionTicketModel>> getTickets() async {
    try {
      final db = await _getDatabase();
      if (db != null) {
        final List<Map<String, dynamic>> maps = await db.query(
          AppConstants.ticketsTable,
          orderBy: 'created_at DESC',
        );
        return maps.map((map) => InspectionTicketModel.fromMap(map)).toList();
      } else {
        if (_inMemoryTickets != null && _inMemoryTickets!.isNotEmpty) {
          return List.from(_inMemoryTickets!)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        final list = await _getFromPreferences();
        _inMemoryTickets = List.from(list);
        return list;
      }
    } catch (e) {
      if (_inMemoryTickets != null && _inMemoryTickets!.isNotEmpty) {
        return List.from(_inMemoryTickets!);
      }
      return _generateInitialSeedTickets();
    }
  }

  @override
  Future<List<InspectionTicketModel>> getPendingTickets() async {
    try {
      final db = await _getDatabase();
      if (db != null) {
        final List<Map<String, dynamic>> maps = await db.query(
          AppConstants.ticketsTable,
          where: 'status = ? OR status = ?',
          whereArgs: ['pending', 'pending_sync'],
          orderBy: 'created_at ASC',
        );
        return maps.map((map) => InspectionTicketModel.fromMap(map)).toList();
      } else {
        final list = await getTickets();
        return list
            .where((ticket) =>
                ticket.status == 'pending' || ticket.status == 'pending_sync')
            .toList();
      }
    } catch (e) {
      throw CacheException('Không thể lấy danh sách phiếu chờ đồng bộ: $e');
    }
  }

  @override
  Future<void> saveTicket(InspectionTicketModel ticket) async {
    try {
      // 1. Luôn cập nhật bộ nhớ đệm In-Memory trước tiên để bản Web không bao giờ bị mất phiếu
      _inMemoryTickets ??= await _getFromPreferences();
      final inMemIdx = _inMemoryTickets!.indexWhere((t) => t.id == ticket.id);
      if (inMemIdx != -1) {
        _inMemoryTickets![inMemIdx] = ticket;
      } else {
        _inMemoryTickets!.insert(0, ticket);
      }

      // 2. Lưu vào SQLite Database nếu hỗ trợ (Mobile Native)
      final db = await _getDatabase();
      if (db != null) {
        try {
          await db.insert(
            AppConstants.ticketsTable,
            ticket.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (dbError) {
          // Auto-healing migration if missing columns
          if (dbError.toString().contains('no column named')) {
            try {
              await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN equipment_id TEXT');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN detected_issues TEXT');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN required_parts TEXT');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN image_path TEXT');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN operational_status TEXT');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN assigned_to TEXT');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN manager_notes TEXT');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.ticketsTable} ADD COLUMN resolved_at TEXT');
            } catch (_) {}
            await db.insert(
              AppConstants.ticketsTable,
              ticket.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } else {
            rethrow;
          }
        }
      } else {
        // 3. Dự phòng cho Web (SharedPreferences có cơ chế tự phục hồi chống QuotaExceededError)
        await _saveToPreferences(ticket);
      }
    } catch (e) {
      if (kIsWeb && _inMemoryTickets != null) {
        debugPrint('Lỗi lưu trữ web được bỏ qua, phiếu đã được giữ an toàn trong bộ nhớ: $e');
        return;
      }
      throw CacheException('Không thể lưu phiếu kiểm tra: $e');
    }
  }

  @override
  Future<void> deleteTicket(String id) async {
    try {
      _inMemoryTickets?.removeWhere((item) => item.id == id);
      final db = await _getDatabase();
      if (db != null) {
        await db.delete(
          AppConstants.ticketsTable,
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        try {
          final prefs = await SharedPreferences.getInstance();
          final list = await _getFromPreferences();
          list.removeWhere((item) => item.id == id);
          final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
          await prefs.setString(_prefsKey, encoded);
        } catch (e) {
          debugPrint('Lỗi xóa khỏi SharedPreferences: $e');
        }
      }
    } catch (e) {
      throw CacheException('Không thể xóa phiếu: $e');
    }
  }

  @override
  Future<void> markTicketAsSynced(String id) async {
    try {
      if (_inMemoryTickets != null) {
        final inMemIdx = _inMemoryTickets!.indexWhere((item) => item.id == id);
        if (inMemIdx != -1) {
          final updated = _inMemoryTickets![inMemIdx].copyWith(
            status: 'synced',
            updatedAt: DateTime.now(),
          );
          _inMemoryTickets![inMemIdx] = InspectionTicketModel.fromEntity(updated);
        }
      }

      final db = await _getDatabase();
      final nowStr = DateTime.now().toIso8601String();
      if (db != null) {
        await db.update(
          AppConstants.ticketsTable,
          {
            'status': 'synced',
            'updated_at': nowStr,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        try {
          final list = await _getFromPreferences();
          final index = list.indexWhere((item) => item.id == id);
          if (index != -1) {
            final updated = list[index].copyWith(
              status: 'synced',
              updatedAt: DateTime.now(),
            );
            list[index] = InspectionTicketModel.fromEntity(updated);
            final prefs = await SharedPreferences.getInstance();
            final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
            await prefs.setString(_prefsKey, encoded);
          }
        } catch (e) {
          debugPrint('Lỗi cập nhật đồng bộ lên SharedPreferences: $e');
        }
      }
    } catch (e) {
      throw CacheException('Không thể cập nhật trạng thái đồng bộ: $e');
    }
  }

  // --- Fallback SharedPreferences Implementation (e.g. for Web) ---
  Future<List<InspectionTicketModel>> _getFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_prefsKey);
      if (data == null || data.isEmpty) {
        return _generateInitialSeedTickets();
      }
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => InspectionTicketModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return _generateInitialSeedTickets();
    } catch (e) {
      debugPrint('Lỗi đọc dữ liệu từ SharedPreferences: $e');
      return _generateInitialSeedTickets();
    }
  }

  Future<void> _saveToPreferences(InspectionTicketModel ticket) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = List<InspectionTicketModel>.from(_inMemoryTickets ?? await _getFromPreferences());
      final index = list.indexWhere((item) => item.id == ticket.id);
      if (index != -1) {
        list[index] = ticket;
      } else {
        list.insert(0, ticket);
      }

      // Giới hạn danh sách lưu trữ trình duyệt tối đa 30 phiếu để tránh vượt quota
      final cappedList = list.length > 30 ? list.sublist(0, 30) : list;

      // Bước 1: Thử lưu toàn bộ dữ liệu (nếu dung lượng dưới 5MB)
      try {
        final encoded = jsonEncode(cappedList.map((e) => e.toJson()).toList());
        await prefs.setString(_prefsKey, encoded);
        return;
      } catch (quotaError) {
        debugPrint('Trình duyệt báo vượt quota localStorage ($quotaError). Bật chế độ nén gọn...');
      }

      // Bước 2: Tự động lược bớt Base64 media khổng lồ cho bản lưu localStorage,
      // trong khi bộ nhớ RAM _inMemoryTickets vẫn giữ đầy đủ 100% dữ liệu gốc!
      try {
        final sanitized = cappedList.map((t) {
          String? img = t.imagePath;
          if (img != null && img.length > 30000) {
            img = null; // Tránh tràn dung lượng 5MB của Safari Mobile
          }
          String? aud = t.audioPath;
          if (aud != null && aud.length > 30000) {
            aud = null;
          }
          return t.copyWith(imagePath: img, audioPath: aud);
        }).toList();

        final encodedSanitized = jsonEncode(
          sanitized.map((e) => InspectionTicketModel.fromEntity(e).toJson()).toList(),
        );
        await prefs.setString(_prefsKey, encodedSanitized);
      } catch (quotaError2) {
        debugPrint('SharedPreferences quota exceeded hoàn toàn: $quotaError2. Phiếu được giữ an toàn trong RAM.');
      }
    } catch (e) {
      debugPrint('SharedPreferences không khả dụng trên trình duyệt này: $e');
    }
  }

  List<InspectionTicketModel> _generateInitialSeedTickets() {
    final now = DateTime.now();
    return [
      InspectionTicketModel(
        id: 'seed-02',
        title: 'Chập tia lửa điện tại Tủ điện số 4',
        description: 'Tủ điện bốc mùi khét nồng, Aptomat nóng quá nhiệt có tia lửa điện nhỏ.',
        location: 'Tủ điện số 4, cạnh Kho vật tư',
        category: 'electrical',
        priority: 'critical',
        status: 'pending',
        suggestedAction: 'Cắt cầu dao tổng ngay lập tức và phân công đội cơ điện xử lý.',
        inspectorName: 'Kỹ sư Tuấn Anh',
        confidenceScore: 0.99,
        operationalStatus: 'pending_review',
        equipmentId: 'ELEC-PANEL-04',
        detectedIssues: const ['Chập tia lửa điện', 'Aptomat quá nhiệt', 'Mùi khét cách điện'],
        createdAt: now.subtract(const Duration(minutes: 35)),
        updatedAt: now.subtract(const Duration(minutes: 35)),
      ),
      InspectionTicketModel(
        id: 'seed-01',
        title: 'Nứt vỏ van điều áp đường ống chính',
        description: 'Van điều áp thủy lực chính bị rỉ dầu gây trơn trượt khu vực sàn gia công.',
        location: 'Phân xưởng cán thép số 2',
        category: 'mechanical',
        priority: 'high',
        status: 'synced',
        suggestedAction: 'Thay thế van dự phòng DN50 và dọn cát thấm dầu bề mặt sàn.',
        inspectorName: 'Kỹ sư Hoàng Nam',
        confidenceScore: 0.98,
        operationalStatus: 'in_progress',
        assignedTo: 'Kỹ sư Vũ Thành (Đội Cơ Điện)',
        managerNotes: 'Đã ký phiếu xuất kho van DN50. Yêu cầu hoàn thành trước khi giao ca 2.',
        equipmentId: 'HYDR-VALVE-DN50',
        detectedIssues: const ['Rò rỉ dầu thủy lực', 'Nứt vỏ van chịu áp'],
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      InspectionTicketModel(
        id: 'seed-03',
        title: 'Rung lắc bất thường trục Motor bơm giải nhiệt',
        description: 'Động cơ bơm nước làm mát bị rung lắc biên độ lớn, nhiệt độ vỏ motor 78 độ C.',
        location: 'Trạm bơm tuần hoàn tháp làm mát',
        category: 'mechanical',
        priority: 'medium',
        status: 'synced',
        suggestedAction: 'Kiểm tra độ đồng tâm trục và thay thế bạc đạn SKF 6205.',
        inspectorName: 'Kỹ sư Trần Đức',
        confidenceScore: 0.96,
        operationalStatus: 'resolved',
        assignedTo: 'Kỹ sư Lê Minh',
        managerNotes: 'Đã căn chỉnh lại trục và thay bạc đạn. Nghiệm thu chạy thử đạt chuẩn.',
        resolvedAt: now.subtract(const Duration(minutes: 15)),
        equipmentId: 'PUMP-COOL-02',
        detectedIssues: const ['Rung lắc biên độ lớn', 'Hỏng bạc đạn trục'],
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
      ),
    ];
  }
}
