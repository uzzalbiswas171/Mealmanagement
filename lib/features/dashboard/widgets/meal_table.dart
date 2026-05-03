import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/meal_entry_model.dart';
import 'meal_table_row.dart';

class MealTable extends StatelessWidget {
  final List<MealEntry> entries;
  final MealTableMeta? meta;
  final Map<int, MealEditRecord>? editRecords;
  final void Function(int index)? onEditTap;
  final bool Function(int index)? canEditRow;

  const MealTable({
    super.key,
    required this.entries,
    this.meta,
    this.editRecords,
    this.onEditTap,
    this.canEditRow,
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
          ...entries.asMap().entries.map((e) {
            return Column(
              children: [
                MealTableRow(
                  entry: e.value,
                  isEven: e.key.isEven,
                  onEditTap: (canEditRow == null || canEditRow!(e.key))
                      ? () => onEditTap?.call(e.key)
                      : null,
                  editRecord: editRecords?[e.key],
                ),
                if (e.key < entries.length - 1)
                  const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFF5F5F5),
                  ),
              ],
            );
          }),
          const Divider(height: 1, color: AppColors.greyBorder),
          _buildFooter(entries),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.tableRadius),
          topRight: Radius.circular(AppSpacing.tableRadius),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('Member Name', style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Morning',
              style: AppTextStyles.tableHeader,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Noon',
              style: AppTextStyles.tableHeader,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Night',
              style: AppTextStyles.tableHeader,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildFooter(List<MealEntry> entries) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.tableRadius),
          bottomRight: Radius.circular(AppSpacing.tableRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                meta != null
                    ? 'Edited by ${meta!.editorRole} ${meta!.editorName} • ${meta!.timeAgo}'
                    : '—',
                style: AppTextStyles.metaText,
              ),
            ],
          ),
          () {
            final totalMeals = entries.fold(0.0, (s, e) => s + e.totalMeals);
            final totalCost = totalMeals * (meta?.mealRate ?? 0);
            final formatted = totalCost
                .toStringAsFixed(0)
                .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
            return Text(
              'Total: ৳ $formatted',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.primaryBlue,
                fontFamilyFallback: ['Noto Sans Bengali', 'Roboto'],
              ),
            );
          }(),
        ],
      ),
    );
  }
}
