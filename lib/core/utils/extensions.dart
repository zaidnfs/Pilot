import 'package:intl/intl.dart';

/// Useful Dart extensions for the app.

extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Mask a string: first [visible] chars + "***"
  String masked([int visible = 2]) {
    if (length <= visible) return '$this***';
    return '${substring(0, visible)}***';
  }
}

extension DateTimeExtensions on DateTime {
  /// Format as "12:30 PM"
  String get timeFormatted => DateFormat('h:mm a').format(this);

  /// Format as "Apr 6, 2026"
  String get dateFormatted => DateFormat('MMM d, y').format(this);

  /// Format as "Apr 6, 12:30 PM"
  String get dateTimeFormatted => DateFormat('MMM d, h:mm a').format(this);

  /// Human-friendly "X minutes ago"
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

extension DoubleExtensions on double {
  /// Format as Indian Rupees: "₹100"
  String get inr => '₹${toStringAsFixed(0)}';

  /// Format as Indian Rupees with paise: "₹100.50"
  String get inrPrecise => '₹${toStringAsFixed(2)}';
}
