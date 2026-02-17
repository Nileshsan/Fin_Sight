/// Formatters Utilities
/// String and data formatting utilities

import 'package:intl/intl.dart';

/// Format currency
String formatCurrency(double amount, {String symbol = '\$'}) {
  final formatter = NumberFormat('#,##0.00', 'en_US');
  return '$symbol${formatter.format(amount)}';
}

/// Format percentage
String formatPercentage(double value, {int decimals = 2}) {
  return '${value.toStringAsFixed(decimals)}%';
}

/// Format date
String formatDate(DateTime date, {String pattern = 'MMM dd, yyyy'}) {
  return DateFormat(pattern).format(date);
}

/// Format time
String formatTime(DateTime time, {bool is24Hour = true}) {
  return DateFormat(is24Hour ? 'HH:mm' : 'hh:mm a').format(time);
}

/// Format datetime
String formatDateTime(DateTime dateTime, {String pattern = 'MMM dd, yyyy HH:mm'}) {
  return DateFormat(pattern).format(dateTime);
}

/// Format large numbers
String formatLargeNumber(num value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toStringAsFixed(0);
}

/// Format phone number
String formatPhoneNumber(String phone) {
  // Remove non-digits
  final digits = phone.replaceAll(RegExp(r'[^\d]'), '');

  if (digits.length >= 10) {
    return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
  }

  return phone;
}

/// Capitalize first letter
String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// Capitalize words
String capitalizeWords(String text) {
  return text
      .split(' ')
      .map((word) => capitalize(word))
      .join(' ');
}

/// Truncate text
String truncate(String text, {int length = 50, String suffix = '...'}) {
  if (text.length <= length) return text;
  return text.substring(0, length) + suffix;
}

/// Remove extra whitespace
String normalizeWhitespace(String text) {
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
