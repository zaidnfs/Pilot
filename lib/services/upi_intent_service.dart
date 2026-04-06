import 'package:url_launcher/url_launcher.dart';

/// UPI Intent Service for direct peer-to-peer payments.
///
/// Generates UPI deep links per the NPCI UPI specification and launches
/// the user's preferred UPI app (GPay, PhonePe, Paytm, etc.).
///
/// Per PRD: No internal wallet, no actual escrow. Direct P2P UPI transfer.
/// Commission during Pilot Phase: ₹0.
class UpiIntentService {
  UpiIntentService._();

  /// Generate a UPI deep link URI.
  ///
  /// [payeeVpa] - Traveler's UPI ID (e.g. "user@okhdfcbank")
  /// [payeeName] - Traveler's display name
  /// [amount] - Payment amount in INR
  /// [orderId] - Order ID for transaction reference
  /// [note] - Optional transaction note
  static Uri generateUpiUri({
    required String payeeVpa,
    required String payeeName,
    required double amount,
    required int orderId,
    String? note,
  }) {
    final transactionNote = note ?? 'DashauliConnect-Order-$orderId';

    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': payeeVpa, // Payee VPA
        'pn': payeeName, // Payee Name
        'am': amount.toStringAsFixed(2), // Amount
        'cu': 'INR', // Currency
        'tn': transactionNote, // Transaction Note
        'tr': 'DC$orderId', // Transaction Reference
        'mc': '0000', // Merchant Category (P2P)
      },
    );
  }

  /// Launch UPI payment intent on the device.
  ///
  /// Returns true if the intent was launched successfully.
  /// The actual payment result must be verified separately
  /// (UPI apps don't always return reliable result data).
  static Future<bool> launchPayment({
    required String payeeVpa,
    required String payeeName,
    required double amount,
    required int orderId,
    String? note,
  }) async {
    final uri = generateUpiUri(
      payeeVpa: payeeVpa,
      payeeName: payeeName,
      amount: amount,
      orderId: orderId,
      note: note,
    );

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }

    // Fallback: try launching with external application mode
    return await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  /// Generate a display-friendly UPI link string for sharing.
  static String generatePaymentLink({
    required String payeeVpa,
    required String payeeName,
    required double amount,
    required int orderId,
  }) {
    final uri = generateUpiUri(
      payeeVpa: payeeVpa,
      payeeName: payeeName,
      amount: amount,
      orderId: orderId,
    );
    return uri.toString();
  }

  /// Validate UPI VPA format (basic check).
  /// Full validation requires a PSP lookup which is not available offline.
  static bool isValidVpa(String vpa) {
    // Basic format: username@bankhandle
    final regex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+$');
    return regex.hasMatch(vpa);
  }
}
