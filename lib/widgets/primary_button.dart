import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 🟢 BACKGROUND LOGIC:
    final Color finalBgColor = backgroundColor ??
        (isDestructive ? colorScheme.error : colorScheme.primary);

    // 🟢 FOREGROUND (TEXT) LOGIC:
    final Color finalFgColor = foregroundColor ??
        (isDestructive ? Colors.white : colorScheme.onPrimary);

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: finalBgColor,
          foregroundColor: finalFgColor,
          elevation: 0, // 🟢 Setting this to 0 removes both the base and the press shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Consistent with your containers
          ),
          textStyle: const TextStyle(inherit: false, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}