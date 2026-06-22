import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PasswordStrength {
  final double value;
  final String label;
  final Color color;

  const PasswordStrength({
    required this.value,
    required this.label,
    required this.color,
  });
}

PasswordStrength computePasswordStrength(String password) {
  if (password.isEmpty) {
    return const PasswordStrength(
      value: 0,
      label: '',
      color: Colors.transparent,
    );
  }

  final hasLetters = password.contains(RegExp(r'[a-zA-Z]'));
  final hasNumbers = password.contains(RegExp(r'[0-9]'));
  final hasSpecial = password.contains(RegExp(r'[^a-zA-Z0-9]'));
  final length = password.length;

  if (length < 8 || !hasLetters || !hasNumbers) {
    return PasswordStrength(
      value: 0.33,
      label: 'Weak',
      color: AppColors.error,
    );
  }

  if (hasLetters && hasNumbers && hasSpecial) {
    return const PasswordStrength(
      value: 1.0,
      label: 'Strong',
      color: AppColors.leafGreen,
    );
  }

  return const PasswordStrength(
    value: 0.66,
    label: 'Medium',
    color: Color(0xFFE6A817),
  );
}

class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({
    super.key,
    required this.password,
  });

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = computePasswordStrength(password);
    if (strength.value == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength.value,
            backgroundColor: AppColors.barkCream,
            valueColor: AlwaysStoppedAnimation(strength.color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strength.label,
          style: AppTextStyles.caption.copyWith(color: strength.color),
        ),
        const SizedBox(height: 6),
        _requirement(password.length >= 8, 'At least 8 characters'),
        _requirement(
          password.contains(RegExp(r'[a-zA-Z]')),
          'Include a letter',
        ),
        _requirement(
          password.contains(RegExp(r'[0-9]')),
          'Include a number',
        ),
      ],
    );
  }

  Widget _requirement(bool met, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: met ? AppColors.leafGreen : AppColors.sandyBrown,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: met ? AppColors.leafGreen : AppColors.sandyBrown,
            ),
          ),
        ],
      ),
    );
  }
}
