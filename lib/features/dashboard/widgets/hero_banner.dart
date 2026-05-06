import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive_helper.dart';

class HeroBanner extends StatelessWidget {
  final double myMeals;
  final double mealRate;
  final double myPaid;
  final double totalExtraMarket;
  final double totalNumberOfMembers;

  const HeroBanner({
    super.key,
    required this.myMeals,
    required this.mealRate,
    required this.myPaid,
    required this.totalExtraMarket,
    required this.totalNumberOfMembers,
  });

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _money(double v) => '৳${_fmt(v)}';

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveHelper.heroBannerHeight(context);
    final cost = myMeals * mealRate;
    final extraPerMember = totalNumberOfMembers > 0
        ? totalExtraMarket / totalNumberOfMembers
        : 0.0;
    final totalCost = cost + extraPerMember;
    final pending = myPaid - totalCost;
    final isCredit = pending >= 0;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl:
                'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Container(color: AppColors.primaryBlueLight),
            errorWidget: (context, url, error) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryBlue, Color(0xFF42A5F5)],
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.primaryBlue.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('My Meal Status', style: AppTextStyles.heroSubtitle),
                const SizedBox(height: 6),
                Text(
                  'Total meal = ${_fmt(myMeals)}  |  meal-rate = ${_money(mealRate)}',
                  style: AppTextStyles.heroSubtitle,
                ),
                const SizedBox(height: 2),
                Text(
                  'Paid = ${_money(myPaid)}  |  cost (${_fmt(myMeals)}×${_money(mealRate)}) = ${_money(cost)}',
                  style: AppTextStyles.heroSubtitle,
                ),
                const SizedBox(height: 2),
                Text(
                  'Extra = ${_money(totalExtraMarket)} ÷ ${_fmt(totalNumberOfMembers)} = ${_money(extraPerMember)} | Total = ${_money(totalCost)}',
                  style: AppTextStyles.heroSubtitle,
                ),
                const SizedBox(height: 6),
                Container(
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      isCredit
                          ? Icons.check_circle_outline_rounded
                          : Icons.warning_amber_rounded,
                      size: 14,
                      color: isCredit
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCredit
                          ? 'Surplus (${_money(myPaid)} - ${_money(totalCost)}) = ${_money(pending)}'
                          : 'Due (${_money(totalCost)} - ${_money(myPaid)}) = ${_money(-pending)}',
                      style: AppTextStyles.heroSubtitle.copyWith(
                        color: isCredit
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                Widget row(String label, String value, {bool bold = false}) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: bold
                                      ? FontWeight.w700
                                      : FontWeight.w400)),
                          Text(value,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: bold
                                      ? FontWeight.w700
                                      : FontWeight.w600)),
                        ],
                      ),
                    );
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('My Cost Breakdown',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        row('Total Meals', _fmt(myMeals)),
                        row('Meal Rate', _money(mealRate)),
                        row('Meal Cost', _money(cost)),
                        const Divider(),
                        row('Extra Market (total)', _money(totalExtraMarket)),
                        row('Members', _fmt(totalNumberOfMembers)),
                        row('Extra / Member', _money(extraPerMember)),
                        const Divider(),
                        row('Total Cost', _money(totalCost), bold: true),
                        row('Paid', _money(myPaid), bold: true),
                        const Divider(),
                        row(
                          isCredit ? 'Surplus' : 'Due',
                          _money(pending.abs()),
                          bold: true,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(image: AssetImage("assets/images/Income Chart.gif"))),
              ),
            ),
          )

        ],
      ),
    );
  }
}
