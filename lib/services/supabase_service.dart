import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton access to the Supabase client instance.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static String? get currentUserId => auth.currentUser?.id;

  static bool get isAuthenticated => auth.currentUser != null;
}
