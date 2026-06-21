import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.petalWhite,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ProfileHeader(
            name: 'User',
            phone: '+1 234 567 890',
          ),
          const SizedBox(height: 24),
          _menuItem(
            context,
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => context.push('/settings'),
          ),
          _menuItem(
            context,
            icon: Icons.info_outline,
            label: 'About Tagar',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.earthBrown),
      title: Text(label, style: AppTextStyles.body),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.sandyBrown,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
