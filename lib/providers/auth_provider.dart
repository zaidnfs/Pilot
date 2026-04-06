import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// Provides a stream of auth state changes.
/// Used by the router to redirect unauthenticated users.
final authStateProvider = StreamProvider<AuthState?>((ref) {
  return SupabaseService.auth.onAuthStateChange;
});

/// Provides the current user (nullable).
final currentUserProvider = Provider<User?>((ref) {
  return SupabaseService.auth.currentUser;
});

/// Provides a boolean indicating if the user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
