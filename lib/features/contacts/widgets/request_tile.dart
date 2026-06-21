import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class IncomingRequestTile extends StatelessWidget {
  const IncomingRequestTile({
    super.key,
    required this.tagarId,
    required this.onAccept,
    required this.onReject,
  });

  final String tagarId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.barkCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.sandyBrown,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.petalWhite,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tagarId, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  'Wants to connect',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.leafGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.check,
                  color: AppColors.petalWhite, size: 20),
              onPressed: onAccept,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.close,
                  color: AppColors.petalWhite, size: 20),
              onPressed: onReject,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}

class SentRequestTile extends StatelessWidget {
  const SentRequestTile({
    super.key,
    required this.tagarId,
    required this.status,
  });

  final String tagarId;
  final String status;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (status) {
      'accepted' => ('Accepted', AppColors.leafGreen),
      'rejected' => ('Rejected', AppColors.error),
      _ => ('Pending', AppColors.sandyBrown),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.barkCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.sandyBrown,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.petalWhite,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tagarId, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  'Sent request',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
