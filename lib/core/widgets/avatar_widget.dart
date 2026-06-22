import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 48,
    this.isOnline,
  });

  final String? imageUrl;
  final String name;
  final double size;
  final bool? isOnline;

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (imageUrl != null) {
      avatar = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _placeholder,
        ),
      );
    } else {
      avatar = _placeholder;
    }

    if (isOnline != null) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: isOnline! ? AppColors.leafGreen : AppColors.sandyBrown,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.petalWhite, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
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
