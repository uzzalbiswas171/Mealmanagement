import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class MealBadge extends StatelessWidget {
  final double value;

  const MealBadge({super.key, required this.value});

  String get _label {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = value == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isEmpty ? AppColors.greySurface : AppColors.blueSurface,
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
      ),
      child: Text(
        _label,
        style: AppTextStyles.badgeText.copyWith(
          color: isEmpty ? AppColors.textSecondary : AppColors.primaryBlue,
        ),
      ),
    );
  }
}
