import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.petalWhite,
      appBar: AppBar(title: const Text('Updates')),
      body: Center(
        child: Text('Updates screen', style: AppTextStyles.body),
      ),
    );
  }
}
