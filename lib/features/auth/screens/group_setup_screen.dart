import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/app_state.dart';
import '../../../data/services/group_service.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import 'login_screen.dart';

class GroupSetupScreen extends StatefulWidget {
  const GroupSetupScreen({super.key});

  @override
  State<GroupSetupScreen> createState() => _GroupSetupScreenState();
}

class _GroupSetupScreenState extends State<GroupSetupScreen> {
  final _joinFormKey = GlobalKey<FormState>();
  final _inviteCodeCtrl = TextEditingController();
  bool _joining = false;

  @override
  void dispose() {
    _inviteCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    if (_joinFormKey.currentState?.validate() != true) return;
    setState(() => _joining = true);
    try {
      final groupId = await GroupService.joinGroup(
        _inviteCodeCtrl.text.trim().toUpperCase(),
      );
      if (!mounted) return;
      await context.read<AppState>().loadFromFirestore(groupId);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // blue header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.primaryBlueLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () =>
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (_) => false,
                            ),
                        icon: const Icon(
                          Icons.group_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Set Up Your Group',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a new group or join one',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                child: Column(
                  children: [
                    // // Create group card
                    // _SectionCard(
                    //   icon: Icons.add_circle_outline_rounded,
                    //   title: 'Create New Group',
                    //   subtitle: 'Start a new mess group and invite members',
                    //   child: Form(
                    //     key: _createFormKey,
                    //     child: Column(
                    //       children: [
                    //         _GroupField(
                    //           controller: _groupNameCtrl,
                    //           label: 'Group Name',
                    //           icon: Icons.group_outlined,
                    //           validator: (v) => (v?.trim().isEmpty ?? true)
                    //               ? 'Group name is required'
                    //               : null,
                    //         ),
                    //         const SizedBox(height: 16),
                    //         SizedBox(
                    //           width: double.infinity,
                    //           child: ElevatedButton(
                    //             onPressed: _creating ? null : _createGroup,
                    //             style: ElevatedButton.styleFrom(
                    //               backgroundColor: AppColors.primaryBlue,
                    //               foregroundColor: Colors.white,
                    //               padding:
                    //                   const EdgeInsets.symmetric(vertical: 14),
                    //               shape: RoundedRectangleBorder(
                    //                   borderRadius: BorderRadius.circular(12)),
                    //               elevation: 0,
                    //             ),
                    //             child: _creating
                    //                 ? const SizedBox(
                    //                     width: 20,
                    //                     height: 20,
                    //                     child: CircularProgressIndicator(
                    //                         strokeWidth: 2,
                    //                         color: Colors.white))
                    //                 : Text('Create Group',
                    //                     style: AppTextStyles.headingSmall
                    //                         .copyWith(color: Colors.white)),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),

                    // const SizedBox(height: 16),

                    // // Divider
                    // Row(
                    //   children: [
                    //     const Expanded(child: Divider()),
                    //     Padding(
                    //       padding: const EdgeInsets.symmetric(horizontal: 12),
                    //       child: Text('OR',
                    //           style: AppTextStyles.bodySmall
                    //               .copyWith(color: AppColors.textSecondary)),
                    //     ),
                    //     const Expanded(child: Divider()),
                    //   ],
                    // ),
                    const SizedBox(height: 16),

                    // Join group card
                    _SectionCard(
                      icon: Icons.login_rounded,
                      title: 'Join Existing Group',
                      subtitle: 'Enter the invite code shared by your manager',
                      child: Form(
                        key: _joinFormKey,
                        child: Column(
                          children: [
                            _GroupField(
                              controller: _inviteCodeCtrl,
                              label: 'Invite Code',
                              icon: Icons.vpn_key_outlined,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9]'),
                                ),
                                LengthLimitingTextInputFormatter(8),
                                _UpperCaseFormatter(),
                              ],
                              validator: (v) {
                                if (v?.trim().isEmpty ?? true) {
                                  return 'Invite code is required';
                                }
                                if (v!.trim().length != 8) {
                                  return 'Code must be 8 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _joining ? null : _joinGroup,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryBlue,
                                  side: const BorderSide(
                                    color: AppColors.primaryBlue,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _joining
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Join Group',
                                        style: AppTextStyles.headingSmall
                                            .copyWith(
                                              color: AppColors.primaryBlue,
                                            ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headingSmall.copyWith(fontSize: 15),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _GroupField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _GroupField({
    required this.controller,
    required this.label,
    required this.icon,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
  });

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
  );
  static final _focused = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
  );
  static final _error = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.redAccent),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: AppTextStyles.tableCell,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.scaffoldBg,
        border: _border,
        enabledBorder: _border,
        focusedBorder: _focused,
        errorBorder: _error,
        focusedErrorBorder: _error,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
