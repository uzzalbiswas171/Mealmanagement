import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/app_state.dart';
import '../../../data/models/member_model.dart';
import '../../../data/services/member_service.dart';

class EditMemberSheet extends StatefulWidget {
  final MemberProfile member;
  const EditMemberSheet({super.key, required this.member});

  @override
  State<EditMemberSheet> createState() => _EditMemberSheetState();
}

class _EditMemberSheetState extends State<EditMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _mealCtrl;
  late final TextEditingController _amountCtrl;
  late MemberRole _role;
  late bool _isPaid;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member.name);
    _mealCtrl =
        TextEditingController(text: widget.member.mealCount.toString());
    _amountCtrl = TextEditingController(
        text: widget.member.moneyAmount.abs().toStringAsFixed(0));
    _role = widget.member.role;
    _isPaid = widget.member.isPaid;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mealCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _loading = true);
    try {
      final groupId = context.read<AppState>().groupId!;
      final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
      await MemberService.updateMember(
        groupId: groupId,
        memberId: widget.member.id,
        changes: {
          'displayName': _nameCtrl.text.trim(),
          'role': _role.name,
          'mealCount': int.tryParse(_mealCtrl.text.trim()) ?? 0,
          'moneyAmount': _isPaid ? amount : -amount,
          'isPaid': _isPaid,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '${_nameCtrl.text.trim()} updated successfully!',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(),
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
        backgroundColor: AppColors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE1E7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Member',
                          style: AppTextStyles.headingMedium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Update member details',
                          style: AppTextStyles.metaText,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _loading ? null : _save,
                    child: Text(
                      'Save',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Personal info card
              _SheetSection(
                title: 'PERSONAL INFORMATION',
                children: [
                  _SheetField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Role card
              _SheetSection(
                title: 'GROUP ROLE',
                children: [
                  _RoleChips(
                    selected: _role,
                    onChanged: (r) => setState(() => _role = r),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Stats card
              _SheetSection(
                title: 'MEAL & FINANCIAL',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SheetField(
                          controller: _mealCtrl,
                          label: 'Meal Count',
                          icon: Icons.restaurant_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) =>
                              (v?.trim().isEmpty ?? true) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SheetField(
                          controller: _amountCtrl,
                          label: 'Balance (\$)',
                          icon: Icons.attach_money_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (v) =>
                              (v?.trim().isEmpty ?? true) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PaidToggle(
                    isPaid: _isPaid,
                    onChanged: (v) => setState(() => _isPaid = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    'Save Changes',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sheet Section Card ───────────────────────────────────────────────────────

class _SheetSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SheetSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppSpacing.cardBorderRadius,
        boxShadow: const [AppSpacing.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.tableHeader.copyWith(
              letterSpacing: 0.6,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ─── Text Field ───────────────────────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
  });

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
  );
  static final _focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
  );
  static final _errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.redAccent),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
        focusedBorder: _focusedBorder,
        errorBorder: _errorBorder,
        focusedErrorBorder: _errorBorder,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

// ─── Role Chips ───────────────────────────────────────────────────────────────

class _RoleChips extends StatelessWidget {
  final MemberRole selected;
  final ValueChanged<MemberRole> onChanged;

  const _RoleChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MemberRole.values.map((role) {
        final isSelected = role == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: role != MemberRole.values.last ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  role.label,
                  style: AppTextStyles.badgeText.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Paid / Due Toggle ────────────────────────────────────────────────────────

class _PaidToggle extends StatelessWidget {
  final bool isPaid;
  final ValueChanged<bool> onChanged;

  const _PaidToggle({required this.isPaid, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.payment_rounded,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 10),
        Text('Payment Status', style: AppTextStyles.bodySmall),
        const Spacer(),
        Row(
          children: [
            _StatusChip(
              label: 'Paid',
              isSelected: isPaid,
              selectedColor: AppColors.greenAccent,
              onTap: () => onChanged(true),
            ),
            const SizedBox(width: 8),
            _StatusChip(
              label: 'Due',
              isSelected: !isPaid,
              selectedColor: AppColors.redAccent,
              onTap: () => onChanged(false),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withValues(alpha: 0.12) : AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? selectedColor : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.badgeText.copyWith(
            color: isSelected ? selectedColor : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
