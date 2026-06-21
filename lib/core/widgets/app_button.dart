import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.petalWhite,
            ),
          )
        : Text(label, style: AppTextStyles.button);

    if (!expanded) {
      return ElevatedButton(onPressed: onPressed, child: child);
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: onPressed, child: child),
    );
  }
}
