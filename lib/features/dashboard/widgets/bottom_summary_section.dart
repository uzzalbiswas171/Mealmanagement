import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'summary_card.dart';

class BottomSummarySection extends StatelessWidget {
  final double mealRate;
  final double totalCost;
  final int monthlyMeals;

  const BottomSummarySection({
    super.key,
    required this.mealRate,
    required this.totalCost,
    required this.monthlyMeals,
  });

  String _fmt(double v, {int decimals = 0}) {
    final s = v.toStringAsFixed(decimals);
    final parts = s.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    int start = intPart.length % 3;
    if (start > 0) buf.write(intPart.substring(0, start));
    for (int i = start; i < intPart.length; i += 3) {
      if (buf.isNotEmpty) buf.write(',');
      buf.write(intPart.substring(i, i + 3));
    }
    if (decimals > 0 && parts.length > 1) return '৳ $buf.${parts[1]}';
    return '৳ $buf';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            label: 'Meal Rate',
            value: _fmt(mealRate, decimals: 2),
            backgroundColor: AppColors.greySurface,
            labelColor: AppColors.textSecondary,
            valueColor: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SummaryCard(
            label: 'Monthly Meals',
            value: '$monthlyMeals',
            backgroundColor: AppColors.blueSurface,
            labelColor: AppColors.primaryBlue,
            valueColor: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SummaryCard(
            label: 'Total Cost',
            value: _fmt(totalCost),
            backgroundColor: AppColors.greenLight,
            labelColor: AppColors.greenAccent,
            valueColor: AppColors.greenAccent,
          ),
        ),
      ],
    );
  }
}
