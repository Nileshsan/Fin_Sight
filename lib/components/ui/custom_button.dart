import 'package:flutter/material.dart';

/// Custom Button Widget
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final bool isLoading;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool isIcon;

  const CustomButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.style,
    this.isLoading = false,
    this.width,
    this.height = 50,
    this.icon,
    this.isIcon = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (isIcon && icon != null)
            ? Icon(icon)
            : Text(label);

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: buttonChild,
      ),
    );
  }
}

/// Text Button Widget
class CustomTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? textColor;
  final double fontSize;

  const CustomTextButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.textColor,
    this.fontSize = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? Theme.of(context).primaryColor,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

/// Outlined Button Widget
class CustomOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? borderColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const CustomOutlinedButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.borderColor,
    this.textColor,
    this.width,
    this.height = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: borderColor ?? Theme.of(context).primaryColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor ?? Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
