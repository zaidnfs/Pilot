/// Application-wide constants for Dashauli Connect
class AppConstants {
  AppConstants._();

  // Geofence & matching
  static const int standardCorridorMeters = 500;
  static const int expressCorridorMeters = 1500;

  // Timeouts
  static const Duration orderExpiryStandard = Duration(minutes: 30);
  static const Duration orderExpiryExpress = Duration(minutes: 15);
  static const Duration travelerOfflineTimeout = Duration(minutes: 10);
  static const Duration locationUpdateInterval = Duration(seconds: 10);

  // OTP
  static const int otpLength = 4;

  // UPI
  static const String upiCurrency = 'INR';
  static const String upiMerchantCode = '0000'; // P2P, no merchant category

  // Map defaults (Dashauli / Kursi Road corridor center)
  static const double defaultLat = 26.8620;
  static const double defaultLng = 81.0165;
  static const double defaultZoom = 14.0;

  // Touch targets (per mobile-design skill: min 48dp)
  static const double minTouchTarget = 48.0;

  // Emergency
  static const String emergencyNumber = '112';

  // Delivery bounty floor (minimum ₹5)
  static const double minBounty = 5.0;

  // Platform commission (Phase 1: ₹0)
  static const double platformFee = 0.0;
}
