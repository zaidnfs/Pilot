import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/location_service.dart';
import '../services/supabase_service.dart';

/// Represents the app's dual-mode state: Requester or Traveler.
enum AppMode { requester, traveler }

/// Manages the dual-mode toggle state.
/// When switching to Traveler mode, starts live GPS tracking.
/// When switching to Requester mode, stops tracking.
class ModeNotifier extends StateNotifier<AppMode> {
  ModeNotifier() : super(AppMode.requester);

  Future<void> toggleMode() async {
    if (state == AppMode.requester) {
      await _activateTravelerMode();
    } else {
      await _activateRequesterMode();
    }
  }

  Future<void> setMode(AppMode mode) async {
    if (mode == AppMode.traveler) {
      await _activateTravelerMode();
    } else {
      await _activateRequesterMode();
    }
  }

  Future<void> _activateTravelerMode() async {
    // Ensure location permission
    final hasPermission = await LocationService.ensurePermission();
    if (!hasPermission) return;

    // Update server
    final userId = SupabaseService.currentUserId;
    if (userId != null) {
      await SupabaseService.client.from('profiles').update({
        'active_mode': 'traveler',
        'is_online': true,
      }).eq('id', userId);
    }

    // Start live GPS tracking
    LocationService.startLiveTracking();

    state = AppMode.traveler;
  }

  Future<void> _activateRequesterMode() async {
    // Stop GPS tracking
    await LocationService.stopLiveTracking();

    // Update server
    final userId = SupabaseService.currentUserId;
    if (userId != null) {
      await SupabaseService.client.from('profiles').update({
        'active_mode': 'requester',
        'is_online': false,
      }).eq('id', userId);
    }

    state = AppMode.requester;
  }
}

final modeProvider =
    StateNotifierProvider<ModeNotifier, AppMode>((ref) {
  return ModeNotifier();
});
