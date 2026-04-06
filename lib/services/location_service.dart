import 'dart:async';
import 'package:geolocator/geolocator.dart';

import 'supabase_service.dart';
import '../core/constants/app_constants.dart';

/// Manages GPS location tracking, permissions, and live location
/// broadcasting to Supabase for the "Along the Way" matching engine.
class LocationService {
  LocationService._();

  static StreamSubscription<Position>? _positionStream;

  /// Check and request location permissions.
  /// Returns true if permission is granted.
  static Future<bool> ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Get current position once.
  static Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Start streaming location updates to Supabase.
  /// Called when user enters Traveler mode.
  static void startLiveTracking() {
    _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // Minimum 20m movement before update
        timeLimit: AppConstants.locationUpdateInterval,
      ),
    ).listen((position) async {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      await SupabaseService.client.from('profiles').update({
        'current_lat': position.latitude,
        'current_lng': position.longitude,
        'heading': position.heading,
        'is_online': true,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    });
  }

  /// Stop live tracking (user exits Traveler mode).
  static Future<void> stopLiveTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;

    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    await SupabaseService.client.from('profiles').update({
      'is_online': false,
    }).eq('id', userId);
  }

  /// Calculate distance between two points in meters (Haversine).
  static double distanceBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
