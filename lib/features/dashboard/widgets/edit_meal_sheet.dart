import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/meal_entry_model.dart';

class EditMealSheet extends StatefulWidget {
  final MealEntry entry;
  final ValueChanged<MealEntry> onSave;

  const EditMealSheet({super.key, required this.entry, required this.onSave});

  @override
  State<EditMealSheet> createState() => _EditMealSheetState();
}

class _EditMealSheetState extends State<EditMealSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _morningCtrl;
  late final TextEditingController _noonCtrl;
  late final TextEditingController _nightCtrl;

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

  void _save() {
    if (_formKey.currentState?.validate() != true) return;
    widget.onSave(MealEntry(
      member: widget.entry.member,
      morningMeal: double.tryParse(_morningCtrl.text.trim()) ?? 0,
      noonMeal: double.tryParse(_noonCtrl.text.trim()) ?? 0,
      nightMeal: double.tryParse(_nightCtrl.text.trim()) ?? 0,
    ));
    Navigator.pop(context);
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
                    onPressed: _save,
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
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MealField(
                            controller: _noonCtrl,
                            label: 'Noon',
                            icon: Icons.wb_sunny_rounded,
                            iconColor: const Color(0xFFFBC02D),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MealField(
                            controller: _nightCtrl,
                            label: 'Night',
                            icon: Icons.nightlight_round,
                            iconColor: AppColors.primaryBlue,
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
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded, size: 20),
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

// ─── Meal Number Field ────────────────────────────────────────────────────────

class _MealField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _MealField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.iconColor,
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
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d?')),
      ],
      textAlign: TextAlign.center,
      style: AppTextStyles.headingSmall.copyWith(fontSize: 15),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        if (double.tryParse(v.trim()) == null) return 'Invalid';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.metaText,
        prefixIcon: Icon(icon, size: 16, color: iconColor),
        filled: true,
        fillColor: AppColors.scaffoldBg,
        border: _border,
        enabledBorder: _border,
        focusedBorder: _focusedBorder,
        errorBorder: _errorBorder,
        focusedErrorBorder: _errorBorder,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        errorStyle: const TextStyle(fontSize: 10),
      ),
    );
  }
}
