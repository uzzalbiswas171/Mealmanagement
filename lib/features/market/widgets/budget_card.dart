import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_text_styles.dart';

class BudgetCard extends StatelessWidget {
  final double totalPaid;
  final double totalPending;
  final int paidCount;
  final int totalMembers;
  final double extraMarketTotal;

  const BudgetCard({
    super.key,
    required this.totalPaid,
    required this.totalPending,
    required this.paidCount,
    required this.totalMembers,
    this.extraMarketTotal = 0,
  });

  static String _fmt(double v, {int decimals = 2}) {
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
    return decimals > 0 ? '৳ $buf.${parts[1]}' : '৳ $buf';
  }

  @override
  Widget build(BuildContext context) {
    final dueCount = totalMembers - paidCount;

    return Column(
      children: [
        // ── Main collected card ───────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                top: -10,
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 110,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_upward_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'SENT',
                              style: AppTextStyles.badgeText.copyWith(
                                color: Colors.white,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Monthly Collected',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.80),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmt(totalPaid),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MiniStat(
                        icon: Icons.check_circle_rounded,
                        label: '$paidCount Paid',
                        color: const Color(0xFF69F0AE),
                      ),
                      const SizedBox(width: 16),
                      _MiniStat(
                        icon: Icons.people_rounded,
                        label: '$totalMembers Members',
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── ending row ───────────────────────────────────
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFCC80)),
          ),
          child: Row(
            children: [
              // Container(
              //   width: 36,
              //   height: 36,
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFFFE0B2),
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   child: const Icon(Icons.pending_actions_rounded,
              //       color: Color(0xFFE65100), size: 18),
              // ),
              // const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Total Meal Market',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFFE65100),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        Text(
                          _fmt(totalPaid - totalPending),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Total Extra market',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFFE65100),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        Text(
                          _fmt(extraMarketTotal),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Text(
                          'Total Market Cost',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFFE65100),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                           '${totalPaid - totalPending + extraMarketTotal}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Text(
                          'Available Balance',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFFE65100),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${totalPaid} - ${totalPaid - totalPending + extraMarketTotal}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Text(
                          '',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFFE65100),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _fmt(totalPending - extraMarketTotal),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
