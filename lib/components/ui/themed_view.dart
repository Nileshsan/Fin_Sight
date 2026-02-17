import 'package:flutter/material.dart';

/// Themed View Widget
/// Base widget for consistent theming across screens
class ThemedView extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final bool useSafeArea;

  const ThemedView({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.useSafeArea = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      padding: padding,
      margin: margin,
      child: child,
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return content;
  }
}

/// Gradient View Widget
class GradientView extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final EdgeInsets padding;

  const GradientView({
    Key? key,
    required this.child,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Rounded Container Widget
class RoundedContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;
  final Border? border;
  final BoxShadow? shadow;

  const RoundedContainer({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.borderRadius = 12,
    this.border,
    this.shadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadow != null ? [shadow!] : null,
      ),
      padding: padding,
      child: child,
    );
  }
}
