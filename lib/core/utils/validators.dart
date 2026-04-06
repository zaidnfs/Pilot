/// Input validators for forms across the app.
class Validators {
  Validators._();

  /// Validate Indian phone number (10 digits).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 10) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  /// Validate non-empty text.
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validate positive number.
  static String? positiveNumber(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Amount'} is required';
    }
    final num = double.tryParse(value.trim());
    if (num == null || num <= 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  /// Validate UPI VPA format.
  static String? upiVpa(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'UPI ID is required';
    }
    final regex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+$');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid UPI ID (e.g. name@upi)';
    }
    return null;
  }
}
