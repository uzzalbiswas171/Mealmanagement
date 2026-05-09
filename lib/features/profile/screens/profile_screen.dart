import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/app_state.dart';
import '../../../data/models/member_model.dart';
import '../../../data/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StreamSubscription<DocumentSnapshot>? _memberSub;
  StreamSubscription<DocumentSnapshot>? _groupSub;

  Map<String, dynamic>? _memberData;
  Map<String, dynamic>? _groupData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.read<AppState>();
    if (appState.groupId != null && appState.userId != null && _memberSub == null) {
      _memberSub = FirebaseFirestore.instance
          .collection('groups')
          .doc(appState.groupId)
          .collection('members')
          .doc(appState.userId)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        setState(() => _memberData = snap.data());
      });

      _groupSub = FirebaseFirestore.instance
          .collection('groups')
          .doc(appState.groupId)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        setState(() => _groupData = snap.data());
      });
    }
  }

  @override
  void dispose() {
    _memberSub?.cancel();
    _groupSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = FirebaseAuth.instance.currentUser;

    final displayName = _memberData?['displayName'] as String? ??
        appState.displayName ??
        user?.displayName ??
        'User';
    final email = user?.email ?? '';
    final roleStr = _memberData?['role'] as String? ?? appState.role ?? 'member';
    final role = MemberRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => MemberRole.member,
    );
    final mealCount = (_memberData?['mealCount'] as num?)?.toInt() ?? 0;
    final moneyAmount = (_memberData?['moneyAmount'] as num?)?.toDouble() ?? 0.0;
    final isPaid = _memberData?['isPaid'] as bool? ?? false;
    final joinedAt = (_memberData?['joinedAt'] as Timestamp?)?.toDate().toLocal();
    final groupName = _groupData?['name'] as String? ?? '—';
    final inviteCode = _groupData?['inviteCode'] as String? ?? '—';
    final initials = _initials(displayName);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _ProfileAppBar(),
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.0),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    _HeroSection(
                      initials: initials,
                      displayName: displayName,
                      email: email,
                      role: role,
                      isPaid: isPaid,
                    ),
                    const SizedBox(height: 24),
                    _StatsRow(
                      mealCount: mealCount,
                      moneyAmount: moneyAmount,
                      joinedAt: joinedAt,
                    ),
                    const SizedBox(height: 20),
                    _PersonalInfoCard(
                      displayName: displayName,
                      email: email,
                      phone: _memberData?['phone'] as String? ?? '—',
                      joinedAt: joinedAt,
                    ),
                    const SizedBox(height: 16),
                    _GroupInfoCard(
                      groupName: groupName,
                      role: role,
                      inviteCode: inviteCode,
                    ),
                    const SizedBox(height: 16),
                    const _AccountCard(),
                    const SizedBox(height: 24),
                    const _SignOutButton(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 4),
              Text('My Profile', style: AppTextStyles.appBarTitle),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Section ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final String initials;
  final String displayName;
  final String email;
  final MemberRole role;
  final bool isPaid;

  const _HeroSection({
    required this.initials,
    required this.displayName,
    required this.email,
    required this.role,
    required this.isPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.primaryBlueLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: AppTextStyles.headingLarge.copyWith(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.greenAccent : AppColors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  isPaid ? Icons.check_rounded : Icons.close_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: AppTextStyles.headingLarge.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: role.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: role.color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: role.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                role.label,
                style: AppTextStyles.badgeText.copyWith(
                  color: role.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int mealCount;
  final double moneyAmount;
  final DateTime? joinedAt;

  const _StatsRow({
    required this.mealCount,
    required this.moneyAmount,
    required this.joinedAt,
  });

  String get _balanceLabel {
    final sign = moneyAmount >= 0 ? '+' : '';
    return '$sign৳${moneyAmount.abs().toStringAsFixed(0)}';
  }

  String get _memberSinceLabel {
    if (joinedAt == null) return '—';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[joinedAt!.month - 1]} '${joinedAt!.year.toString().substring(2)}";
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          value: mealCount.toString(),
          label: 'Meals',
          icon: Icons.restaurant_rounded,
          iconColor: AppColors.primaryBlue,
          iconBg: AppColors.blueSurface,
        ),
        const SizedBox(width: 12),
        _StatTile(
          value: _balanceLabel,
          label: 'Balance',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.greenAccent,
          iconBg: AppColors.greenLight,
        ),
        const SizedBox(width: 12),
        _StatTile(
          value: _memberSinceLabel,
          label: 'Member Since',
          icon: Icons.calendar_month_rounded,
          iconColor: const Color(0xFF7B1FA2),
          iconBg: const Color(0xFFF3E5F5),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: AppSpacing.cardBorderRadius,
          boxShadow: const [AppSpacing.cardShadow],
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTextStyles.headingSmall.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.metaText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Personal Info Card ───────────────────────────────────────────────────────

class _PersonalInfoCard extends StatelessWidget {
  final String displayName;
  final String email;
  final String phone;
  final DateTime? joinedAt;

  const _PersonalInfoCard({
    required this.displayName,
    required this.email,
    required this.phone,
    required this.joinedAt,
  });

  String get _joinedLabel {
    if (joinedAt == null) return '—';
    return '${joinedAt!.day.toString().padLeft(2, '0')} / '
        '${joinedAt!.month.toString().padLeft(2, '0')} / '
        '${joinedAt!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'PERSONAL INFORMATION',
      icon: Icons.person_outline_rounded,
      children: [
        _InfoRow(
          icon: Icons.badge_outlined,
          label: 'Full Name',
          value: displayName,
        ),
        _InfoRow(
          icon: Icons.mail_outline_rounded,
          label: 'Email',
          value: email.isEmpty ? '—' : email,
        ),
        _InfoRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: phone.isEmpty ? '—' : phone,
        ),
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Joined',
          value: _joinedLabel,
          isLast: true,
        ),
      ],
    );
  }
}

// ─── Group Info Card ──────────────────────────────────────────────────────────

class _GroupInfoCard extends StatelessWidget {
  final String groupName;
  final MemberRole role;
  final String inviteCode;

  const _GroupInfoCard({
    required this.groupName,
    required this.role,
    required this.inviteCode,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'GROUP INFORMATION',
      icon: Icons.groups_outlined,
      children: [
        _InfoRow(
          icon: Icons.home_work_outlined,
          label: 'Group Name',
          value: groupName,
        ),
        _InfoRow(
          icon: Icons.shield_outlined,
          label: 'Role',
          value: role.label,
          valueColor: role.color,
        ),
        _InviteCodeRow(inviteCode: inviteCode),
      ],
    );
  }
}

class _InviteCodeRow extends StatelessWidget {
  final String inviteCode;
  const _InviteCodeRow({required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          const Icon(Icons.tag_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Invite Code', style: AppTextStyles.bodyMedium),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Invite code copied!',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                  backgroundColor: AppColors.greenAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  inviteCode,
                  style: AppTextStyles.tableCell.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.copy_rounded, size: 14, color: AppColors.primaryBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Account Card ─────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ACCOUNT',
      icon: Icons.manage_accounts_outlined,
      children: [
        _ActionRow(
          icon: Icons.lock_outline_rounded,
          label: 'Change Password',
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _ChangePasswordSheet(),
          ),
        ),
        _ActionRow(
          icon: Icons.notifications_outlined,
          label: 'Notification Preferences',
          onTap: () {},
        ),
        _ActionRow(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Settings',
          onTap: () {},
          isLast: true,
        ),
      ],
    );
  }
}

// ─── Sign Out Button ──────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await AuthService.signOut();
          if (!context.mounted) return;
          context.read<AppState>().clear();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text(
          'Sign Out',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.redAccent,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.redAccent,
          side: BorderSide(
            color: AppColors.redAccent.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppSpacing.cardBorderRadius,
        boxShadow: const [AppSpacing.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.blueSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: AppTextStyles.tableHeader.copyWith(
                    letterSpacing: 0.6,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ...children,
        ],
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: AppTextStyles.bodyMedium),
              ),
              Text(
                value,
                style: AppTextStyles.tableCell.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 46, endIndent: 16, color: Color(0xFFF0F0F0)),
      ],
    );
  }
}

// ─── Action Row ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: AppTextStyles.tableCell),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 46, endIndent: 16, color: Color(0xFFF0F0F0)),
      ],
    );
  }
}

// ─── Change Password Sheet ────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.updatePassword(_newPassCtrl.text.trim());
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password updated successfully',
              style: TextStyle(color: Colors.white, fontSize: 13)),
          backgroundColor: AppColors.greenAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'requires-recent-login'
          ? 'Please sign out and sign back in, then try again.'
          : e.message ?? 'Failed to update password.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13)),
          backgroundColor: AppColors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.blueSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.primaryBlue, size: 18),
                ),
                const SizedBox(width: 10),
                Text('Change Password', style: AppTextStyles.headingMedium),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _newPassCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'New password is required';
                if (v.trim().length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPassCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please confirm your password';
                if (v.trim() != _newPassCtrl.text.trim()) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text('Save Password',
                        style: AppTextStyles.headingSmall
                            .copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
