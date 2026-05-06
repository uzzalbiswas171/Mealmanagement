import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

const _morningNoonCutoffHour = 8;  // 8:00 AM
const _nightCutoffHour = 16;       // 4:00 PM

/// Returns which slots are locked for editing.
/// Managers are never locked.
/// Non-managers:
///   • Morning & Noon lock after 8:00 AM today
///   • Night locks after 4:00 PM today
({bool morning, bool noon, bool night}) lockedMealSlots(
  DateTime date, {
  bool isManager = false,
}) {
  if (isManager) return (morning: false, noon: false, night: false);
  final now = DateTime.now();
  final isToday = date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
  return (
    morning: isToday && now.hour >= _morningNoonCutoffHour,
    noon: isToday && now.hour >= _morningNoonCutoffHour,
    night: isToday && now.hour >= _nightCutoffHour,
  );
}

/// Show when all slots are locked (after 4 PM for non-managers).
void showAllMealsLockedMessage(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text(
        'Meal editing is closed after 4:00 PM.',
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
      backgroundColor: AppColors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ),
  );
}
