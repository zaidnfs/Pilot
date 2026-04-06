import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';

/// Provides the current device position.
final currentPositionProvider = FutureProvider<Position?>((ref) async {
  final hasPermission = await LocationService.ensurePermission();
  if (!hasPermission) return null;
  return LocationService.getCurrentPosition();
});
