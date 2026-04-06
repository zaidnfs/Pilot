class UpiGenerator {
  /// Generates a UPI deep link intent URL.
  static String generateUpiLink({
    required String payeeAddress,
    required String payeeName,
    required double amount,
    String? transactionNote,
  }) {
    final baseUrl = 'upi://pay';
    final params = {
      'pa': payeeAddress,
      'pn': payeeName,
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      if (transactionNote != null) 'tn': transactionNote,
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$baseUrl?$queryString';
  }
}
