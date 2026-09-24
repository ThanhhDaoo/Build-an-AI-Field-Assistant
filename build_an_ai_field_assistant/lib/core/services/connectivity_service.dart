import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network Connectivity Monitoring Service for Online/Offline coordination
class ConnectivityService {
  final Connectivity _connectivity;
  final _connectionStatusController = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _connectionStatusController.stream;

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      _isOnline = true;
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final bool online = results.isNotEmpty &&
        !results.every((element) => element == ConnectivityResult.none);

    if (_isOnline != online) {
      _isOnline = online;
      _connectionStatusController.add(_isOnline);
      debugPrint('Network connectivity state changed: isOnline=$_isOnline');
    }
  }

  Future<bool> checkCurrentConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      return _isOnline;
    } catch (e) {
      return _isOnline;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}
