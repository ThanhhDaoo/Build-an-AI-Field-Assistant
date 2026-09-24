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
              equipment_id TEXT,
              detected_issues TEXT,
              required_parts TEXT,
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
        return await _getFromPreferences();
      }
    } catch (e) {
      throw CacheException('Không thể tải danh sách phiếu: $e');
    }
  }

  @override
  Future<List<InspectionTicketModel>> getPendingTickets() async {
    try {
      final db = await _getDatabase();
      if (db != null) {
        final List<Map<String, dynamic>> maps = await db.query(
          AppConstants.ticketsTable,
          where: 'status = ?',
          whereArgs: ['pending_sync'],
          orderBy: 'created_at ASC',
        );
        return maps.map((map) => InspectionTicketModel.fromMap(map)).toList();
      } else {
        final list = await _getFromPreferences();
        return list.where((ticket) => ticket.status == 'pending_sync').toList();
      }
    } catch (e) {
      throw CacheException('Không thể lấy danh sách phiếu chờ đồng bộ: $e');
    }
  }

  @override
  Future<void> saveTicket(InspectionTicketModel ticket) async {
    try {
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
        await _saveToPreferences(ticket);
      }
    } catch (e) {
      throw CacheException('Không thể lưu phiếu kiểm tra: $e');
    }
  }

  @override
  Future<void> deleteTicket(String id) async {
    try {
      final db = await _getDatabase();
      if (db != null) {
        await db.delete(
          AppConstants.ticketsTable,
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        final prefs = await SharedPreferences.getInstance();
        final list = await _getFromPreferences();
        list.removeWhere((item) => item.id == id);
        final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
        await prefs.setString(_prefsKey, encoded);
      }
    } catch (e) {
      throw CacheException('Không thể xóa phiếu: $e');
    }
  }

  @override
  Future<void> markTicketAsSynced(String id) async {
    try {
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
      }
    } catch (e) {
      throw CacheException('Không thể cập nhật trạng thái đồng bộ: $e');
    }
  }

  // --- Fallback SharedPreferences Implementation (e.g. for Web) ---
  Future<List<InspectionTicketModel>> _getFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefsKey);
    if (data == null || data.isEmpty) {
      return _generateInitialSeedTickets();
    }
    try {
      final List decoded = jsonDecode(data) as List;
      return decoded.map((e) => InspectionTicketModel.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return _generateInitialSeedTickets();
    }
  }

  Future<void> _saveToPreferences(InspectionTicketModel ticket) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _getFromPreferences();
    final index = list.indexWhere((item) => item.id == ticket.id);
    if (index != -1) {
      list[index] = ticket;
    } else {
      list.insert(0, ticket);
    }
    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  List<InspectionTicketModel> _generateInitialSeedTickets() {
    final now = DateTime.now();
    return [
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
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      InspectionTicketModel(
        id: 'seed-02',
        title: 'Chập tia lửa điện tại Tủ điện số 4',
        description: 'Tủ điện bốc mùi khét nồng, Aptomat nóng quá nhiệt có tia lửa điện nhỏ.',
        location: 'Tủ điện số 4, cạnh Kho vật tư',
        category: 'electrical',
        priority: 'critical',
        status: 'pending_sync',
        suggestedAction: 'Cắt cầu dao tổng ngay lập tức và phân công đội cơ điện xử lý.',
        inspectorName: 'Kỹ sư Tuấn Anh',
        confidenceScore: 0.99,
        createdAt: now.subtract(const Duration(minutes: 35)),
        updatedAt: now.subtract(const Duration(minutes: 35)),
      ),
    ];
  }
}
