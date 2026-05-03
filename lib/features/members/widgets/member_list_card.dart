import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/member_model.dart';
import 'member_row.dart';

class MemberListCard extends StatelessWidget {
  final List<MemberProfile> members;
  final int totalCount;
  final bool isManager;

  const MemberListCard({
    super.key,
    required this.members,
    required this.totalCount,
    this.isManager = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppSpacing.cardBorderRadius,
        boxShadow: const [AppSpacing.cardShadow],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: AppColors.greyBorder),
          ...members.asMap().entries.map((e) => MemberRow(
                member: e.value,
                isLast: e.key == members.length - 1,
                isManager: isManager,
              )),
          _buildViewAll(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.tableRadius),
          topRight: Radius.circular(AppSpacing.tableRadius),
        ),
      ),
      child: Row(
        children: [
          // 48px avatar + 12px gap = 60px to align with MemberRow
          const SizedBox(width: 60),
          Expanded(
            flex: 3,
            child: Text('NAME', style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: 2,
            child: Text('MEALS', style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: 2,
            child: Text('MONEY', style: AppTextStyles.tableHeader),
          ),
          SizedBox(
            width: 70,
            child: Text(
              'ACTION',
              style: AppTextStyles.tableHeader,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAll() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.tableRadius),
          bottomRight: Radius.circular(AppSpacing.tableRadius),
        ),
      ),
      child: Text(
        '$totalCount Members Total',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
