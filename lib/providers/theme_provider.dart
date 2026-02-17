import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Theme Mode Provider
/// Manages application theme (light/dark)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  /// Set theme mode
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  /// Toggle between light and dark
  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  /// Set light theme
  void setLightTheme() {
    state = ThemeMode.light;
  }

  /// Set dark theme
  void setDarkTheme() {
    state = ThemeMode.dark;
  }

  /// Set system theme
  void setSystemTheme() {
    state = ThemeMode.system;
  }
}

/// Current Brightness Provider
/// Provides the current brightness based on theme mode
final currentBrightnessProvider = Provider<Brightness>((ref) {
  final themeMode = ref.watch(themeModeProvider);

  if (themeMode == ThemeMode.light) {
    return Brightness.light;
  } else if (themeMode == ThemeMode.dark) {
    return Brightness.dark;
  }

  // System default - return light theme as fallback
  return Brightness.light;
});

/// Theme Data Provider
/// Provides the appropriate theme data
final themeDataProvider = Provider<ThemeData>((ref) {
  final brightness = ref.watch(currentBrightnessProvider);
  
  // Import your theme constants here
  // For now, returning basic Material themes
  if (brightness == Brightness.dark) {
    return ThemeData.dark();
  } else {
    return ThemeData.light();
  }
});
