import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/app_state.dart';
import '../../../data/models/member_model.dart';
import '../../../data/services/member_service.dart';
import 'edit_member_sheet.dart';

class MemberDetailSheet extends StatelessWidget {
  final MemberProfile member;

  const MemberDetailSheet({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final isManager = context.read<AppState>().role == 'manager';
    final isPositive = member.moneyAmount >= 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE1E7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Avatar + name ──────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: member.avatarUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _InitialsAvatar(
                              initials: member.initials,
                              size: 80,
                            ),
                            errorWidget: (_, __, ___) => _InitialsAvatar(
                              initials: member.initials,
                              size: 80,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          member.name,
                          style: AppTextStyles.headingMedium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: member.role.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            member.role.label,
                            style: AppTextStyles.badgeText.copyWith(
                              color: member.role.color,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Stats row ──────────────────────────────────
                  Row(
                    children: [
                      _StatBox(
                        label: 'Meals',
                        value: '${member.mealCount}',
                        valueColor: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 10),
                      _StatBox(
                        label: 'Balance',
                        value: member.formattedMoney,
                        valueColor: isPositive
                            ? AppColors.greenAccent
                            : AppColors.redAccent,
                      ),
                      const SizedBox(width: 10),
                      _StatBox(
                        label: 'Payment',
                        value: member.isPaid ? 'Paid' : 'Due',
                        valueColor: member.isPaid
                            ? AppColors.greenAccent
                            : AppColors.redAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Info card ──────────────────────────────────
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: member.phone.isEmpty ? '—' : member.phone,
                      ),
                      _InfoRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: member.email.isEmpty ? '—' : member.email,
                      ),
                      _InfoRow(
                        icon: Icons.attach_money_rounded,
                        label: 'Monthly Contribution',
                        value: member.monthlyContribution == 0
                            ? '—'
                            : '৳ ${member.monthlyContribution.toStringAsFixed(0)}',
                      ),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Joined',
                        value: member.joinedAt == null
                            ? '—'
                            : _formatDate(member.joinedAt!),
                        isLast: true,
                      ),
                    ],
                  ),

                  if (isManager) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    EditMemberSheet(member: member),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                              side: const BorderSide(
                                  color: AppColors.primaryBlue),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _confirmDelete(context),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.redAccent,
                              side: const BorderSide(
                                  color: AppColors.redAccent),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final groupId = context.read<AppState>().groupId;
    if (groupId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text(
          'Are you sure you want to delete "${member.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.pop(context);
    await MemberService.deleteMember(
        groupId: groupId, memberId: member.id);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;

  const _InitialsAvatar({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.blueSurface,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.headingMedium.copyWith(
          color: AppColors.primaryBlue,
          fontSize: size * 0.28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatBox({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.headingSmall.copyWith(
                color: valueColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.metaText),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.blueSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.metaText),
                    const SizedBox(height: 2),
                    Text(value, style: AppTextStyles.tableCell),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 64, endIndent: 16,
              color: Color(0xFFF0F0F0)),
      ],
    );
  }
}
