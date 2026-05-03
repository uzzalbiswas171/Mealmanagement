import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const StatusBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  const StatusBadge.today({super.key})
      : text = 'Today',
        backgroundColor = AppColors.greenLight,
        textColor = AppColors.greenAccent;

  const StatusBadge.pending({super.key})
      : text = 'PENDING',
        backgroundColor = AppColors.redLight,
        textColor = AppColors.redAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
      ),
      child: Text(
        text,
        style: AppTextStyles.badgeText.copyWith(color: textColor),
      ),
    );
  }
}
