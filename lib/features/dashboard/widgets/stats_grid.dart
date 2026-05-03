import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/stats_card_model.dart';
import 'stats_card.dart';

class StatsGrid extends StatelessWidget {
  final String managerName;
  final String bazarKariName;
  final int todayNoon;
  final int todayNight;
  final int pendingMarket;
  final double lastMarketAmount;
  final String lastMarketDate;

  const StatsGrid({
    super.key,
    required this.managerName,
    required this.bazarKariName,
    required this.todayNoon,
    required this.todayNight,
    required this.pendingMarket,
    required this.lastMarketAmount,
    required this.lastMarketDate,
  });

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    int start = s.length % 3;
    if (start > 0) buf.write(s.substring(0, start));
    for (int i = start; i < s.length; i += 3) {
      if (buf.isNotEmpty) buf.write(',');
      buf.write(s.substring(i, i + 3));
    }
    return '৳ $buf';
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      StatsCardData(
        title: "Today's Meal",
        value: 'Night: $todayNight',
        subtitle: 'Noon: $todayNoon',
        icon: Icons.lunch_dining_rounded,
        iconColor: AppColors.primaryBlue,
        iconBackground: AppColors.blueSurface,
      ),
      StatsCardData(
        title: 'Manager',
        value: managerName.isEmpty ? '—' : managerName,
        icon: Icons.shield_rounded,
        iconColor: AppColors.primaryBlue,
        iconBackground: AppColors.blueSurface,
      ),
      StatsCardData(
        title: 'Bazar Kari',
        value: bazarKariName.isEmpty ? 'Unassigned' : bazarKariName,
        subtitle: '$pendingMarket pending',
        icon: Icons.shopping_basket_rounded,
        iconColor: AppColors.redAccent,
        iconBackground: AppColors.redLight,
        badgeText: pendingMarket > 0 ? 'PENDING' : 'CLEAR',
        badgeColor: pendingMarket > 0 ? AppColors.redLight : AppColors.greenLight,
        badgeTextColor: pendingMarket > 0 ? AppColors.redAccent : AppColors.greenAccent,
      ),
      StatsCardData(
        title: 'Last Market',
        value: lastMarketAmount > 0 ? _fmt(lastMarketAmount) : '—',
        subtitle: lastMarketDate.isEmpty ? '—' : lastMarketDate,
        icon: Icons.access_time_rounded,
        iconColor: AppColors.textSecondary,
        iconBackground: AppColors.greySurface,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 600 ? 4 : 2;
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(
                    width: itemWidth,
                    child: StatsCard(data: card),
                  ))
              .toList(),
        );
      },
    );
  }
}
