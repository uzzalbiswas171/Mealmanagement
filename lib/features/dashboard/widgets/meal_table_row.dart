import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/meal_entry_model.dart';
import 'meal_badge.dart';

class MealTableRow extends StatelessWidget {
  final MealEntry entry;
  final bool isEven;
  final VoidCallback? onEditTap;
  final MealEditRecord? editRecord;

  const MealTableRow({
    super.key,
    required this.entry,
    this.isEven = true,
    this.onEditTap,
    this.editRecord,
  });

  static String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  static String _fmtTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day.toString().padLeft(2, '0')}-${months[dt.month - 1]}-${dt.year}  $h:$min $amPm';
  }

  String _slot(double prev, double current) {
    if (prev == current) return _fmt(current);
    return '${_fmt(prev)}→${_fmt(current)}';
  }

  @override
  Widget build(BuildContext context) {
    final bg = isEven ? Colors.white : const Color(0xFFFAFAFA);

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── main row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.blueSurface,
                        child: Text(
                          entry.member.initials,
                          style: AppTextStyles.tableHeader.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          entry.member.name,
                          style: AppTextStyles.tableCell,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: MealBadge(value: entry.morningMeal)),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: MealBadge(value: entry.noonMeal)),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: MealBadge(value: entry.nightMeal)),
                ),
                SizedBox(
                  width: 28,
                  child: IconButton(
                    onPressed: onEditTap,
                    icon: const Icon(
                      Icons.more_vert,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ),
              ],
            ),
          ),

          // ── edit history strip ────────────────────────────────────
          if (editRecord != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.blueSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 13,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'M: ${_slot(editRecord!.prevMorning, entry.morningMeal)}'
                      '  ·  N: ${_slot(editRecord!.prevNoon, entry.noonMeal)}'
                      '  ·  Night: ${_slot(editRecord!.prevNight, entry.nightMeal)}'
                      '  ·  ${_fmtTime(editRecord!.editedAt)}',
                      style: AppTextStyles.metaText.copyWith(
                        color: AppColors.primaryBlue,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
