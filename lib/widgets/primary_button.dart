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
    final Color finalBgColor = backgroundColor ?? 
        (isDestructive ? Colors.redAccent : theme.colorScheme.primary);
    final Color finalFgColor = foregroundColor ?? Colors.white;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 54, 
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: finalBgColor,
          foregroundColor: finalFgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            // 🟢 CHANGED TO 16: This creates a "Rounded Square" look instead of an Oval
            borderRadius: BorderRadius.circular(16), 
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}