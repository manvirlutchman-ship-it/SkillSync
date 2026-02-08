import 'package:flutter/material.dart';

class RatingRow extends StatelessWidget {
  final int rating;
  final double size;

  const RatingRow({
    super.key,
    required this.rating,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          Icons.star_rounded, // Rounded variant
          size: size,
          // If active: Slate. If inactive: Very light gray.
          color: index < rating 
              ? theme.colorScheme.primary 
              : theme.colorScheme.primary.withOpacity(0.1),
        );
      }),
    );
  }
}