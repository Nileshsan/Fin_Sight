import 'package:flutter/material.dart';

/// Themed Text Widget
/// Displays text with theme-aware styling
class ThemedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const ThemedText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign = TextAlign.left,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.fontSize,
    this.fontWeight,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ??
          TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
          ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Heading Text Widget
class HeadingText extends StatelessWidget {
  final String text;
  final int level; // 1-6
  final TextAlign textAlign;
  final Color? color;

  const HeadingText(
    this.text, {
    Key? key,
    this.level = 1,
    this.textAlign = TextAlign.left,
    this.color,
  }) : super(key: key);

  TextStyle _getHeadingStyle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    switch (level) {
      case 1:
        return textTheme.displayLarge ?? const TextStyle();
      case 2:
        return textTheme.displayMedium ?? const TextStyle();
      case 3:
        return textTheme.displaySmall ?? const TextStyle();
      case 4:
        return textTheme.headlineMedium ?? const TextStyle();
      case 5:
        return textTheme.headlineSmall ?? const TextStyle();
      case 6:
        return textTheme.titleLarge ?? const TextStyle();
      default:
        return textTheme.bodyLarge ?? const TextStyle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = _getHeadingStyle(context);
    final finalStyle = color != null
        ? baseStyle.copyWith(color: color)
        : baseStyle;

    return Text(
      text,
      style: finalStyle,
      textAlign: textAlign,
    );
  }
}

/// Body Text Widget
class BodyText extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final Color? color;
  final bool bold;

  const BodyText(
    this.text, {
    Key? key,
    this.textAlign = TextAlign.left,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.bold = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Caption Text Widget
class CaptionText extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final Color? color;

  const CaptionText(
    this.text, {
    Key? key,
    this.textAlign = TextAlign.left,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: color ?? Theme.of(context).textTheme.bodySmall?.color,
      ),
      textAlign: textAlign,
    );
  }
}
