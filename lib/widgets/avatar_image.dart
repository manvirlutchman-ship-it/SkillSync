import 'package:flutter/material.dart';

class AvatarImage extends StatelessWidget {
  final String? path;
  final double radius;

  const AvatarImage({super.key, this.path, this.radius = 40});

  @override
  Widget build(BuildContext context) {
    // 1. Handle Empty/Null state
    if (path == null || path!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE8E8ED),
        child: Icon(Icons.person_rounded, color: const Color(0xFF86868B), size: radius),
      );
    }

    // 2. Logic: Is it an asset path or a web URL?
    bool isAsset = path!.startsWith('assets/');

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      backgroundImage: isAsset 
          ? AssetImage(path!) as ImageProvider
          : NetworkImage(path!) as ImageProvider,
      // Error fallback
      onBackgroundImageError: (exception, stackTrace) {
        debugPrint("Image Load Error: $exception");
      },
    );
  }
}