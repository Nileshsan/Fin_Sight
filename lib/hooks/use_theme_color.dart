import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Custom hook equivalent: useThemeColor
/// Provides access to theme-specific colors
class UseThemeColor {
  /// Get color based on theme brightness
  static Color getColor(
    BuildContext context, {
    required Color lightColor,
    required Color darkColor,
  }) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark ? darkColor : lightColor;
  }

  /// Get themed text color
  static Color getTextColor(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark
        ? AppColors.darkText
        : AppColors.black;
  }

  /// Get themed background color
  static Color getBackgroundColor(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark
        ? AppColors.darkBg
        : AppColors.white;
  }

  /// Get themed surface color
  static Color getSurfaceColor(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark
        ? AppColors.darkSurface
        : AppColors.gray50;
  }

  /// Get themed border color
  static Color getBorderColor(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark
        ? AppColors.gray700
        : AppColors.gray200;
  }

  /// Get primary brand color (same for both themes)
  static Color getPrimaryColor() {
    return AppColors.primary;
  }

  /// Get secondary color (same for both themes)
  static Color getSecondaryColor() {
    return AppColors.secondary;
  }

  /// Get accent color (same for both themes)
  static Color getAccentColor() {
    return AppColors.accent;
  }

  /// Get status colors
  static Color getSuccessColor() => AppColors.success;
  static Color getErrorColor() => AppColors.error;
  static Color getWarningColor() => AppColors.warning;
  static Color getInfoColor() => AppColors.info;
}
