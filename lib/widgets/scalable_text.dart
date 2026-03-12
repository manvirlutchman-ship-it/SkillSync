import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/font_size_provider.dart';

class ScalableText extends StatelessWidget {
  final String data;
  final double baseFontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? height;

  const ScalableText(
    this.data, {
    required this.baseFontSize,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.style,
    this.maxLines,
    this.overflow,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scaleFactor = context.watch<FontSizeProvider>().scaleFactor;
    final scaledSize = baseFontSize * scaleFactor;

    return Text(
      data,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: scaledSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
      ),
    );
  }
}