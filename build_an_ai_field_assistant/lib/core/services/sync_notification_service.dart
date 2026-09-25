import 'dart:async';
import 'package:flutter/foundation.dart';

/// Event payload emitted when offline background sync finishes syncing tickets
class SyncNotificationEvent {
  final int syncedCount;
  final String message;
  final DateTime timestamp;

  SyncNotificationEvent({
    required this.syncedCount,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'SyncNotificationEvent($message)';
}

/// Service managing background and in-app synchronization feedback notifications
class SyncNotificationService {
  final _syncStreamController = StreamController<SyncNotificationEvent>.broadcast();
  SyncNotificationEvent? _lastEvent;

  /// Stream of synchronization events fired upon background or manual sync completion
  Stream<SyncNotificationEvent> get onSyncNotification => _syncStreamController.stream;

  /// The most recent sync event emitted
  SyncNotificationEvent? get lastEvent => _lastEvent;

  /// Notify the application that [count] tickets have successfully synced
  void notifySyncSuccess(int count) {
    if (count <= 0) return;
    final event = SyncNotificationEvent(
      syncedCount: count,
      message: '✓ Đã tự động đồng bộ thành công $count phiếu kiểm tra lên máy chủ!',
    );
    _lastEvent = event;
    _syncStreamController.add(event);
    debugPrint('SyncNotification: ${event.message}');
  }

  /// Reset the last notification
  void clearLastEvent() {
    _lastEvent = null;
  }

  /// Clean up stream resources
  void dispose() {
    _syncStreamController.close();
  }
}
