import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/meal_entry_model.dart';

class EditMealSheet extends StatefulWidget {
  final MealEntry entry;
  final Future<void> Function(MealEntry) onSave;
  final bool lockMorning;
  final bool lockNoon;
  final bool lockNight;

  const EditMealSheet({
    super.key,
    required this.entry,
    required this.onSave,
    this.lockMorning = false,
    this.lockNoon = false,
    this.lockNight = false,
  });

  @override
  State<EditMealSheet> createState() => _EditMealSheetState();
}

class _EditMealSheetState extends State<EditMealSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _morningCtrl;
  late final TextEditingController _noonCtrl;
  late final TextEditingController _nightCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _morningCtrl = TextEditingController(text: _fmt(widget.entry.morningMeal));
    _noonCtrl = TextEditingController(text: _fmt(widget.entry.noonMeal));
    _nightCtrl = TextEditingController(text: _fmt(widget.entry.nightMeal));
  }

  @override
  void dispose() {
    _morningCtrl.dispose();
    _noonCtrl.dispose();
    _nightCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(MealEntry(
        member: widget.entry.member,
        morningMeal: widget.lockMorning
            ? widget.entry.morningMeal
            : double.tryParse(_morningCtrl.text.trim()) ?? 0,
        noonMeal: widget.lockNoon
            ? widget.entry.noonMeal
            : double.tryParse(_noonCtrl.text.trim()) ?? 0,
        nightMeal: widget.lockNight
            ? widget.entry.nightMeal
            : double.tryParse(_nightCtrl.text.trim()) ?? 0,
      ));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final anyLocked =
        widget.lockMorning || widget.lockNoon || widget.lockNight;

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

              // header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Meals',
                          style: AppTextStyles.headingMedium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('Update meal counts for this member',
                            style: AppTextStyles.metaText),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      'Save',
                      style: AppTextStyles.headingSmall
                          .copyWith(color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // member info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: AppSpacing.cardBorderRadius,
                  boxShadow: const [AppSpacing.cardShadow],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.blueSurface,
                      child: Text(
                        widget.entry.member.initials,
                        style: AppTextStyles.headingSmall
                            .copyWith(color: AppColors.primaryBlue),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.entry.member.name,
                            style: AppTextStyles.headingSmall),
                        const SizedBox(height: 2),
                        Text(
                          'Total: ${_fmt(widget.entry.totalMeals)} meals',
                          style: AppTextStyles.metaText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // lock info banner
              if (anyLocked) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: AppSpacing.cardBorderRadius,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock_outlined,
                          size: 15, color: AppColors.redAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Morning & Noon locked after 8:00 AM',
                        style: AppTextStyles.metaText
                            .copyWith(color: AppColors.redAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // meal fields card
              Container(
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
                      'MEAL COUNTS',
                      style: AppTextStyles.tableHeader.copyWith(
                        letterSpacing: 0.6,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _MealField(
                            controller: _morningCtrl,
                            label: 'Morning',
                            icon: Icons.wb_sunny_outlined,
                            iconColor: const Color(0xFFF57C00),
                            readOnly: widget.lockMorning,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MealField(
                            controller: _noonCtrl,
                            label: 'Noon',
                            icon: Icons.wb_sunny_rounded,
                            iconColor: const Color(0xFFFBC02D),
                            readOnly: widget.lockNoon,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MealField(
                            controller: _nightCtrl,
                            label: 'Night',
                            icon: Icons.nightlight_round,
                            iconColor: AppColors.primaryBlue,
                            readOnly: widget.lockNight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryBlue,
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Save Changes',
                              style: AppTextStyles.headingSmall.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ],
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

// ─── Meal Number Field ────────────────────────────────────────────────────────

class _MealField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool readOnly;

  const _MealField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.readOnly = false,
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
      enabled: !readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      textAlign: TextAlign.center,
      style: AppTextStyles.headingSmall.copyWith(
        fontSize: 15,
        color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
      ),
      validator: readOnly
          ? null
          : (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final parsed = double.tryParse(v.trim());
              if (parsed == null || parsed < 0) return 'Invalid';
              return null;
            },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.metaText,
        prefixIcon: Icon(
          readOnly ? Icons.lock_outline : icon,
          size: 16,
          color: readOnly ? AppColors.textSecondary : iconColor,
        ),
        filled: true,
        fillColor: readOnly ? AppColors.greySurface : AppColors.scaffoldBg,
        border: _border,
        enabledBorder: _border,
        focusedBorder: _focusedBorder,
        errorBorder: _errorBorder,
        focusedErrorBorder: _errorBorder,
        disabledBorder: _border,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        errorStyle: const TextStyle(fontSize: 10),
      ),
    );
  }
}
