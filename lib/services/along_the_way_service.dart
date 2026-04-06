import 'dart:math';

import 'supabase_service.dart';
import '../models/profile.dart';
import '../core/constants/app_constants.dart';

/// "Along the Way" Matching Engine
///
/// Finds active Travelers whose GPS position falls within a corridor
/// of the line-string from Store → Customer location.
///
/// Uses PostGIS ST_DWithin on the server for accurate geodesic matching.
/// Falls back to client-side Haversine when offline (via PowerSync data).
class AlongTheWayService {
  AlongTheWayService._();

  // ─── Server-side matching (PostGIS RPC) ────────────────────

  /// Find travelers along the route from [storeLat]/[storeLng] to
  /// [customerLat]/[customerLng] within a [corridorMeters] buffer.
  ///
  /// Calls the Supabase RPC function `find_travelers_along_route`.
  static Future<List<TravelerMatch>> findTravelers({
    required double storeLat,
    required double storeLng,
    required double customerLat,
    required double customerLng,
    int? corridorMeters,
  }) async {
    final radius = corridorMeters ?? AppConstants.standardCorridorMeters;

    final response = await SupabaseService.client.rpc(
      'find_travelers_along_route',
      params: {
        'p_store_lat': storeLat,
        'p_store_lng': storeLng,
        'p_customer_lat': customerLat,
        'p_customer_lng': customerLng,
        'p_corridor_meters': radius,
      },
    );

    final data = response as List<dynamic>;
    return data
        .map((json) =>
            TravelerMatch.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Convenience: find travelers for Standard delivery (500m corridor).
  static Future<List<TravelerMatch>> findStandardTravelers({
    required double storeLat,
    required double storeLng,
    required double customerLat,
    required double customerLng,
  }) =>
      findTravelers(
        storeLat: storeLat,
        storeLng: storeLng,
        customerLat: customerLat,
        customerLng: customerLng,
        corridorMeters: AppConstants.standardCorridorMeters,
      );

  /// Convenience: find travelers for Express delivery (1500m corridor).
  static Future<List<TravelerMatch>> findExpressTravelers({
    required double storeLat,
    required double storeLng,
    required double customerLat,
    required double customerLng,
  }) =>
      findTravelers(
        storeLat: storeLat,
        storeLng: storeLng,
        customerLat: customerLat,
        customerLng: customerLng,
        corridorMeters: AppConstants.expressCorridorMeters,
      );

  // ─── Client-side fallback (offline matching) ───────────────

  /// Calculates perpendicular distance from a point to a line segment.
  /// Used for offline matching when PostGIS is not available.
  ///
  /// All coordinates in degrees. Returns distance in meters.
  static double pointToSegmentDistance({
    required double pointLat,
    required double pointLng,
    required double segStartLat,
    required double segStartLng,
    required double segEndLat,
    required double segEndLng,
  }) {
    // Convert to radians
    final pLat = _toRad(pointLat);
    final pLng = _toRad(pointLng);
    final aLat = _toRad(segStartLat);
    final aLng = _toRad(segStartLng);
    final bLat = _toRad(segEndLat);
    final bLng = _toRad(segEndLng);

    // Vector from A to B
    final abLat = bLat - aLat;
    final abLng = bLng - aLng;

    // Vector from A to P
    final apLat = pLat - aLat;
    final apLng = pLng - aLng;

    // Project AP onto AB, clamped to [0, 1]
    final abLenSq = abLat * abLat + abLng * abLng;
    double t = 0;
    if (abLenSq > 0) {
      t = (apLat * abLat + apLng * abLng) / abLenSq;
      t = t.clamp(0.0, 1.0);
    }

    // Closest point on segment
    final closestLat = aLat + t * abLat;
    final closestLng = aLng + t * abLng;

    // Haversine distance from point to closest point on segment
    return _haversine(pLat, pLng, closestLat, closestLng);
  }

  /// Filter a list of profiles to those within [corridorMeters] of the
  /// Store→Customer segment. Used for offline/local matching.
  static List<Profile> filterProfilesAlongRoute({
    required List<Profile> profiles,
    required double storeLat,
    required double storeLng,
    required double customerLat,
    required double customerLng,
    int corridorMeters = 500,
  }) {
    return profiles.where((p) {
      if (p.currentLat == null || p.currentLng == null) return false;
      if (!p.isOnline || !p.aadhaarVerified) return false;
      if (p.activeMode != 'traveler') return false;

      final distance = pointToSegmentDistance(
        pointLat: p.currentLat!,
        pointLng: p.currentLng!,
        segStartLat: storeLat,
        segStartLng: storeLng,
        segEndLat: customerLat,
        segEndLng: customerLng,
      );

      return distance <= corridorMeters;
    }).toList()
      ..sort((a, b) {
        // Sort by distance to store
        final dA = _haversine(
          _toRad(a.currentLat!),
          _toRad(a.currentLng!),
          _toRad(storeLat),
          _toRad(storeLng),
        );
        final dB = _haversine(
          _toRad(b.currentLat!),
          _toRad(b.currentLng!),
          _toRad(storeLat),
          _toRad(storeLng),
        );
        return dA.compareTo(dB);
      });
  }

  // ─── Math helpers ──────────────────────────────────────────

  static const double _earthRadius = 6371000; // meters

  static double _toRad(double deg) => deg * pi / 180;

  static double _haversine(
      double lat1, double lng1, double lat2, double lng2) {
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadius * c;
  }
}

/// A matched Traveler from the PostGIS query with distance info.
class TravelerMatch {
  final String id;
  final String fullName;
  final String phone;
  final String? aadhaarMaskedName;
  final String? aadhaarPhotoUrl;
  final double currentLat;
  final double currentLng;
  final double? heading;
  final double distanceMeters;

  const TravelerMatch({
    required this.id,
    required this.fullName,
    required this.phone,
    this.aadhaarMaskedName,
    this.aadhaarPhotoUrl,
    required this.currentLat,
    required this.currentLng,
    this.heading,
    required this.distanceMeters,
  });

  factory TravelerMatch.fromJson(Map<String, dynamic> json) =>
      TravelerMatch(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        phone: json['phone'] as String,
        aadhaarMaskedName: json['aadhaar_masked_name'] as String?,
        aadhaarPhotoUrl: json['aadhaar_photo_url'] as String?,
        currentLat: (json['current_lat'] as num).toDouble(),
        currentLng: (json['current_lng'] as num).toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
        distanceMeters: (json['distance_meters'] as num).toDouble(),
      );
}
