import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/models/member_model.dart';
import '../../../data/services/member_service.dart';
import '../widgets/member_stat_card.dart';
import '../widgets/member_list_card.dart';
import '../widgets/quick_link_card.dart';
import 'add_member_screen.dart';

class MembersScreenBody extends StatefulWidget {
  const MembersScreenBody({super.key});

  @override
  State<MembersScreenBody> createState() => _MembersScreenBodyState();
}

class _MembersScreenBodyState extends State<MembersScreenBody> {
  Stream<QuerySnapshot>? _stream;
  String? _groupId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gid = context.read<AppState>().groupId;
    if (gid != null && gid != _groupId) {
      _groupId = gid;
      _stream = MemberService.watchMembers(gid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.screenPadding(context);

    if (_stream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        final members = (snapshot.data?.docs
            .map((d) => MemberProfile.fromFirestore(d))
            .toList() ?? [])
          ..sort((a, b) => a.name.compareTo(b.name));

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildPageHeader(context),
                    const SizedBox(height: 24),
                    _buildStatCards(members.length),
                    const SizedBox(height: 28),
                    _buildManageMembersHeader(),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ))
                    else if (members.isEmpty)
                      _buildEmptyState()
                    else
                      MemberListCard(
                        members: members,
                        totalCount: members.length,
                        isManager: context.read<AppState>().role == 'manager',
                      ),
                    const SizedBox(height: 24),
                    QuickLinkCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Payment History',
                      subtitle: 'Audit all member transactions',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    QuickLinkCard(
                      icon: Icons.manage_accounts_rounded,
                      title: 'Group Roles',
                      subtitle: 'Assign permissions & titles',
                      onTap: () {},
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Members',
                style: AppTextStyles.headingLarge.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage group contributions & meals',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (context.read<AppState>().role == 'manager')
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMemberScreen()),
              ),
              icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
              padding: const EdgeInsets.all(14),
            ),
          ),
      ],

    );
  }

  Widget _buildStatCards(int count) {
    return Row(
      children: [
        Expanded(
          child: MemberStatCard(
            label: 'Total Members',
            value: count.toString(),
            valueColor: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: MemberStatCard(
            label: 'Active This Month',
            value: count.toString(),
            valueColor: AppColors.greenAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildManageMembersHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.blueSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.settings_rounded, color: AppColors.primaryBlue, size: 20),
        ),
        const SizedBox(width: 10),
        Text('Manage Members', style: AppTextStyles.headingMedium),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.people_outline_rounded,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('No members yet',
                style: AppTextStyles.headingSmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Add members using the + button above',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
