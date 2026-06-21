import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class LanguageStoreScreen extends StatelessWidget {
  const LanguageStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.petalWhite,
      appBar: AppBar(title: const Text('Language Store')),
      body: Center(
        child: Text('Language store screen', style: AppTextStyles.body),
      ),
    );
  }
}
