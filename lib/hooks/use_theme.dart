import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';

/// Custom hook equivalent: useTheme
/// Provides access to theme data and switching
class UseTheme {
  final WidgetRef ref;

  UseTheme(this.ref);

  /// Get light theme
  ThemeData get lightTheme => AppTheme.lightTheme();

  /// Get dark theme
  ThemeData get darkTheme => AppTheme.darkTheme();

  /// Get current theme based on brightness
  ThemeData getThemeForBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }
}

/// Helper function to use theme in widgets
UseTheme useTheme(WidgetRef ref) {
  return UseTheme(ref);
}
