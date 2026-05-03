import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/member_model.dart';
import 'edit_member_sheet.dart';
import 'member_detail_sheet.dart';

class MemberRow extends StatelessWidget {
  final MemberProfile member;
  final bool isLast;
  final bool isManager;

  const MemberRow({
    super.key,
    required this.member,
    this.isLast = false,
    this.isManager = false,
  });

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MemberDetailSheet(member: member),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = member.moneyAmount >= 0;

    return Column(
      children: [
        InkWell(
          onTap: () => _openDetail(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Avatar
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: member.avatarUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _Initials(member: member),
                    errorWidget: (context, url, error) =>
                        _Initials(member: member),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + role
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, style: AppTextStyles.tableCell),
                      const SizedBox(height: 2),
                      Text(
                        member.role.label,
                        style: AppTextStyles.metaText.copyWith(
                          color: member.role.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Meals
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${member.mealCount}',
                          style: AppTextStyles.tableCell),
                      const SizedBox(height: 2),
                      Text('This month', style: AppTextStyles.metaText),
                    ],
                  ),
                ),

                // Money
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.formattedMoney,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: isPositive
                              ? AppColors.greenAccent
                              : AppColors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.isPaid ? 'Paid' : 'Due',
                        style: AppTextStyles.metaText,
                      ),
                    ],
                  ),
                ),

                // Action
                if (isManager)
                  IconButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => EditMemberSheet(member: member),
                    ),
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                  )
                else
                  const SizedBox(width: 40),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 76,
            endIndent: 16,
            color: Color(0xFFF0F0F0),
          ),
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  final MemberProfile member;
  const _Initials({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.blueSurface,
      alignment: Alignment.center,
      child: Text(
        member.initials,
        style: AppTextStyles.headingSmall.copyWith(
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }
}
