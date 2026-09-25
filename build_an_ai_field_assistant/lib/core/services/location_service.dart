import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Service responsible for GPS hardware access, permission checks and coordinate formatting
class LocationService {
  final Future<Position?> Function()? mockPositionProvider;

  LocationService({this.mockPositionProvider});

  /// Format latitude and longitude coordinates into standardized GPS text:
  /// Example: "10.7769° N, 106.7009° E (Vị trí GPS)"
  static String formatCoordinates(double latitude, double longitude) {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lngDir = longitude >= 0 ? 'E' : 'W';
    final latStr = latitude.abs().toStringAsFixed(4);
    final lngStr = longitude.abs().toStringAsFixed(4);

    return '$latStr° $latDir, $lngStr° $lngDir (Vị trí GPS)';
  }

  /// Check if device location services (GPS) are turned on
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location service status: $e');
      return false;
    }
  }

  /// Check current location permission status
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permissions from system
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Fetch current GPS position with permission resolution and timeout protection
  Future<Position?> getCurrentPosition({
    Duration timeLimit = const Duration(seconds: 10),
  }) async {
    final provider = mockPositionProvider;
    if (provider != null) {
      return await provider();
    }
    try {
      // 1. Check if location hardware is enabled
      final isServiceEnabled = await isLocationServiceEnabled();
      if (!isServiceEnabled) {
        debugPrint('Location service is disabled on device');
        return null;
      }

      // 2. Check permission
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission was denied by user');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return null;
      }

      // 3. Acquire GPS Position
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
    } catch (e) {
      debugPrint('Failed to acquire GPS position: $e');
      return null;
    }
  }

  /// Convenience 1-touch helper: Fetch coordinates and return formatted location string
  /// Returns null if permission is denied or location could not be determined.
  Future<String?> getCurrentFormattedLocation() async {
    final position = await getCurrentPosition();
    if (position == null) return null;
    return formatCoordinates(position.latitude, position.longitude);
  }
}
