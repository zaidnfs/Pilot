class AadhaarParser {
  /// Basic mock parser for Aadhaar QR code or details
  /// Returns a map of parsed details if successful.
  static Map<String, dynamic>? parseQr(String qrData) {
    // In a real app, parse the XML or specific string format of Aadhaar QR
    if (qrData.isEmpty) return null;

    // Mock parsing
    if (qrData.contains('xml')) {
      return {
        'uid': 'XXXX-XXXX-1234',
        'name': 'John Doe',
        'yob': '1990',
        'gender': 'M',
      };
    }
    return null;
  }

  static bool isValidAadhaarNumber(String aadhaar) {
    final cleanAadhaar = aadhaar.replaceAll(RegExp(r'\s|-'), '');
    return cleanAadhaar.length == 12 && int.tryParse(cleanAadhaar) != null;
  }
}
