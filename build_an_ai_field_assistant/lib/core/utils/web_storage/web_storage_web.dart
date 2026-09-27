import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

const String _dbName = 'ai_field_assistant_v1';
const String _storeName = 'tickets_store';
const String _ticketsKey = 'cached_inspection_tickets';

/// Helper mở kết nối IndexedDB sử dụng package:web
Future<web.IDBDatabase?> _openIndexedDb() {
  final completer = Completer<web.IDBDatabase?>();
  try {
    final request = web.window.indexedDB.open(_dbName, 1);

    request.onupgradeneeded = ((web.IDBVersionChangeEvent event) {
      final db = request.result as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName);
      }
    }).toJS;

    request.onsuccess = ((web.Event event) {
      completer.complete(request.result as web.IDBDatabase);
    }).toJS;

    request.onerror = ((web.Event event) {
      completer.complete(null);
    }).toJS;
  } catch (e) {
    debugPrint('Lỗi khởi tạo IndexedDB: $e');
    completer.complete(null);
  }
  return completer.future;
}

Future<bool> saveTicketsImpl(String jsonStr) async {
  bool idbSuccess = false;

  // 1. Lưu vào IndexedDB (Hỗ trợ dung lượng lớn, lưu trữ vĩnh viễn)
  try {
    final db = await _openIndexedDb();
    if (db != null) {
      final completer = Completer<bool>();
      final txn = db.transaction(_storeName.toJS, 'readwrite');
      final store = txn.objectStore(_storeName);
      final putReq = store.put(jsonStr.toJS, _ticketsKey.toJS);

      putReq.onsuccess = ((web.Event e) {
        completer.complete(true);
      }).toJS;

      putReq.onerror = ((web.Event e) {
        completer.complete(false);
      }).toJS;

      idbSuccess = await completer.future;
      db.close();
    }
  } catch (e) {
    debugPrint('Lỗi lưu IndexedDB: $e');
  }

  // 2. Lưu dự phòng vào window.localStorage
  try {
    web.window.localStorage.setItem(_ticketsKey, jsonStr);
  } catch (_) {
    // Nếu localStorage bị đầy (vượt 5MB của Safari), IndexedDB đã lưu trữ an toàn
  }

  return idbSuccess;
}

Future<String?> loadTicketsImpl() async {
  // 1. Ưu tiên đọc từ IndexedDB
  try {
    final db = await _openIndexedDb();
    if (db != null) {
      final completer = Completer<String?>();
      final txn = db.transaction(_storeName.toJS, 'readonly');
      final store = txn.objectStore(_storeName);
      final getReq = store.get(_ticketsKey.toJS);

      getReq.onsuccess = ((web.Event e) {
        final result = getReq.result;
        if (result != null && result.isA<JSString>()) {
          completer.complete((result as JSString).toDart);
        } else {
          completer.complete(null);
        }
      }).toJS;

      getReq.onerror = ((web.Event e) {
        completer.complete(null);
      }).toJS;

      final idbData = await completer.future;
      db.close();
      if (idbData != null && idbData.isNotEmpty) {
        return idbData;
      }
    }
  } catch (e) {
    debugPrint('Lỗi đọc IndexedDB: $e');
  }

  // 2. Dự phòng đọc từ localStorage
  try {
    final lsData = web.window.localStorage.getItem(_ticketsKey);
    if (lsData != null && lsData.isNotEmpty) {
      return lsData;
    }
  } catch (e) {
    debugPrint('Lỗi đọc localStorage: $e');
  }

  return null;
}

/// Nén ảnh camera độ phân giải cao thành JPEG siêu gọn (40KB - 80KB) qua HTML Canvas
Future<String?> compressImageToJpegImpl(
  Uint8List bytes, {
  int maxWidth = 1024,
  double quality = 0.75,
}) async {
  try {
    final blob = web.Blob([bytes.toJS].toJS);
    final url = web.URL.createObjectURL(blob);
    final img = web.HTMLImageElement();
    img.src = url;

    final completer = Completer<String?>();

    img.onload = ((web.Event event) {
      try {
        int width = img.naturalWidth;
        int height = img.naturalHeight;
        if (width <= 0) width = 1024;
        if (height <= 0) height = 768;

        if (width > maxWidth) {
          final ratio = maxWidth / width;
          width = maxWidth;
          height = (height * ratio).round();
        }

        final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
        canvas.width = width;
        canvas.height = height;

        final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
        ctx.drawImage(img, 0, 0, width.toDouble(), height.toDouble());

        final dataUrl = canvas.toDataURL('image/jpeg', quality.toJS);
        web.URL.revokeObjectURL(url);
        completer.complete(dataUrl);
      } catch (err) {
        web.URL.revokeObjectURL(url);
        completer.complete(null);
      }
    }).toJS;

    img.onerror = ((web.Event event) {
      web.URL.revokeObjectURL(url);
      completer.complete(null);
    }).toJS;

    return await completer.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        web.URL.revokeObjectURL(url);
        return null;
      },
    );
  } catch (e) {
    debugPrint('Lỗi nén ảnh qua Canvas Web: $e');
    return null;
  }
}
