import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/avatar_widget.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.phone,
  });

  final String name;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AvatarWidget(name: name, size: 80),
        const SizedBox(height: 12),
        Text(name, style: AppTextStyles.h1),
        const SizedBox(height: 4),
        Text(phone, style: AppTextStyles.label),
      ],
    );
  }
}
