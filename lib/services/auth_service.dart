import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Authentication service for phone-based OTP login via Supabase Auth.
/// Follows auth-implementation-patterns skill: session-based, secure storage.
class AuthService {
  AuthService._();

  static final _auth = SupabaseService.auth;

  /// Send OTP to the user's phone number.
  /// [phone] must include country code, e.g. "+919876543210"
  static Future<void> sendOtp(String phone) async {
    await _auth.signInWithOtp(phone: phone);
  }

  /// Verify the OTP code sent to [phone].
  /// Returns the authenticated session on success.
  static Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    final response = await _auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
    return response;
  }

  /// Update user metadata (e.g., full_name during onboarding).
  static Future<void> updateUserMetadata({
    required String fullName,
  }) async {
    await _auth.updateUser(
      UserAttributes(data: {'full_name': fullName}),
    );
  }

  /// Sign out the current user.
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current session (may be null if not authenticated).
  static Session? get currentSession => _auth.currentSession;

  /// Stream of auth state changes for reactive UI.
  static Stream<AuthState> get onAuthStateChange =>
      _auth.onAuthStateChange;
}
