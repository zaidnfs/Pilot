import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import '../services/supabase_service.dart';

/// Fetches and caches the current user's profile.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final userId = SupabaseService.currentUserId;
  if (userId == null) return null;

  final response = await SupabaseService.client
      .from('profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();

  if (response == null) return null;
  return Profile.fromJson(response);
});

/// Notifier for updating profile data.
class ProfileNotifier extends StateNotifier<AsyncValue<Profile?>> {
  ProfileNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final response = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      state = AsyncValue.data(
        response != null ? Profile.fromJson(response) : null,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async => _load();

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    await SupabaseService.client
        .from('profiles')
        .update(updates)
        .eq('id', userId);

    await _load();
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<Profile?>>((ref) {
  return ProfileNotifier();
});
