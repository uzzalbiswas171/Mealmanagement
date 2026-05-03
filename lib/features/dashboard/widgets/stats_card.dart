import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/stats_card_model.dart';
import '../../../shared/widgets/status_badge.dart';

class StatsCard extends StatelessWidget {
  final StatsCardData data;

  const StatsCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppSpacing.cardBorderRadius,
        boxShadow: const [AppSpacing.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: data.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 20),
              ),
              if (data.badgeText != null)
                StatusBadge(
                  text: data.badgeText!,
                  backgroundColor: data.badgeColor!,
                  textColor: data.badgeTextColor!,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(data.title, style: AppTextStyles.bodySmall),
          const SizedBox(height: 2),
          Text(data.value, style: AppTextStyles.headingSmall),
          if (data.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(data.subtitle!, style: AppTextStyles.metaText.copyWith(fontSize: 9)),
          ],
        ],
      ),
    );
  }
}
