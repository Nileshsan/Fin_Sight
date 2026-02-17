import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// Custom hook equivalent: useColorScheme
/// Provides access to color scheme based on platform and brightness
class UseColorScheme {
  /// Get platform-specific color scheme
  static ColorScheme getColorScheme({
    required Brightness brightness,
  }) {
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1), // Primary color
      brightness: brightness,
    );
  }

  /// Check if using dark mode
  static bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  /// Get current brightness
  static Brightness getBrightness(BuildContext context) {
    return MediaQuery.of(context).platformBrightness;
  }

  /// Get web-specific color scheme
  static ColorScheme getWebColorScheme({
    required Brightness brightness,
  }) {
    // For web, we might want different colors
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: brightness,
    );
  }
}

/// Helper to check if platform is web
bool get isWebPlatform => !Platform.isAndroid && !Platform.isIOS;
