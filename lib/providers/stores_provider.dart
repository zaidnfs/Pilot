import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store.dart';

import '../core/dummy_data.dart';

/// Provides a list of all active stores.
final storesProvider = FutureProvider<List<Store>>((ref) async {
  // TEMP: Return dummy data for UI visualization instead of Supabase query
  return DummyData.stores;
});

/// Provides nearby stores sorted by distance from a given location.
final nearbyStoresProvider =
    FutureProvider.family<List<Store>, ({double lat, double lng})>(
        (ref, location) async {
  // Fetch all active stores and sort client-side
  // (PostGIS ordering would be ideal but requires an RPC)
  final stores = await ref.watch(storesProvider.future);

  final sorted = [...stores]..sort((a, b) {
      final distA = _roughDistance(location.lat, location.lng, a.lat, a.lng);
      final distB = _roughDistance(location.lat, location.lng, b.lat, b.lng);
      return distA.compareTo(distB);
    });

  return sorted;
});

/// Provides a single store by ID.
final storeByIdProvider =
    FutureProvider.family<Store?, int>((ref, storeId) async {
  // TEMP: Return dummy data
  return DummyData.stores
      .firstWhere((s) => s.id == storeId, orElse: () => DummyData.stores.first);
});

/// Rough distance estimate using equirectangular approximation.
/// Good enough for sorting within a small area like Dashauli corridor.
double _roughDistance(double lat1, double lng1, double lat2, double lng2) {
  const double r = 6371000; // Earth radius in meters
  final dLat = (lat2 - lat1) * 3.14159265 / 180;
  final dLng = (lng2 - lng1) * 3.14159265 / 180;
  return r * (dLat * dLat + dLng * dLng).abs();
}
