import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 48,
  });

  final String? imageUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _placeholder,
        ),
      );
    }
    return _placeholder;
  }

  Widget get _placeholder => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.sandyBrown,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              color: AppColors.petalWhite,
              fontSize: size * 0.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}
