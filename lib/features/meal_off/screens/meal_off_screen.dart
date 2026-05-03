import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/app_state.dart';
import '../../../data/services/meal_service.dart';

class MealOffScreen extends StatefulWidget {
  const MealOffScreen({super.key});

  @override
  State<MealOffScreen> createState() => _MealOffScreenState();
}

class _MealOffScreenState extends State<MealOffScreen> {
  StreamSubscription<QuerySnapshot>? _sub;
  Map<String, _DayData> _dataMap = {};
  bool _loading = true;
  final Set<String> _saving = {};

  late final List<DateTime> _days;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Tomorrow through next 30 days
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _days = List.generate(
      30,
      (i) {
        final d = tomorrow.add(Duration(days: i));
        return DateTime(d.year, d.month, d.day);
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
  }

  void _subscribe() {
    final appState = context.read<AppState>();
    final groupId = appState.groupId;
    final userId = appState.userId;
    if (groupId == null || userId == null) return;

    final from = _days.first;
    final to = _days.last.add(const Duration(days: 1));

    _sub?.cancel();
    _sub = MealService.watchMealsForDateRange(groupId, from, to).listen((snap) {
      if (!mounted) return;
      final map = <String, _DayData>{};
      for (final doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        if (d['memberId'] != userId) continue;
        final ts = d['entryDate'] as Timestamp?;
        if (ts == null) continue;
        final date = ts.toDate().toLocal();
        map[_dateKey(date)] = _DayData(
          morning: (d['morningMeal'] as num?)?.toDouble() ?? 1,
          noon: (d['noonMeal'] as num?)?.toDouble() ?? 1,
          night: (d['nightMeal'] as num?)?.toDouble() ?? 1,
        );
      }
      setState(() {
        _dataMap = map;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _toggleSlot(DateTime date, String slot) async {
    final appState = context.read<AppState>();
    final groupId = appState.groupId;
    final userId = appState.userId;
    if (groupId == null || userId == null) return;

    final key = _dateKey(date);
    final defMorning = appState.defaultMorning.toDouble();
    final defNoon = appState.defaultNoon.toDouble();
    final defNight = appState.defaultNight.toDouble();
    final current = _dataMap[key] ??
        _DayData(morning: defMorning, noon: defNoon, night: defNight);

    double morning = current.morning;
    double noon = current.noon;
    double night = current.night;
    switch (slot) {
      case 'morning':
        morning = morning > 0 ? 0 : defMorning;
      case 'noon':
        noon = noon > 0 ? 0 : defNoon;
      case 'night':
        night = night > 0 ? 0 : defNight;
    }

    final savingKey = '$key.$slot';
    setState(() => _saving.add(savingKey));
    try {
      await MealService.upsertMeal(
        groupId: groupId,
        memberId: userId,
        memberName: appState.displayName ?? 'Unknown',
        date: date,
        morning: morning,
        noon: noon,
        night: night,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 13)),
          backgroundColor: AppColors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving.remove(savingKey));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildList(),
    );
  }

  Widget _buildList() {
    final appState = context.read<AppState>();
    final defMorning = appState.defaultMorning.toDouble();
    final defNoon = appState.defaultNoon.toDouble();
    final defNight = appState.defaultNight.toDouble();

    final offCount = _dataMap.values
        .where((d) => d.morning == 0 && d.noon == 0 && d.night == 0)
        .length;

    return Column(
      children: [
        if (offCount > 0) _buildSummaryBanner(offCount),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: _days.length,
            itemBuilder: (ctx, i) {
              final day = _days[i];
              final key = _dateKey(day);
              final data = _dataMap[key] ??
                  _DayData(morning: defMorning, noon: defNoon, night: defNight);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DayCard(
                  date: day,
                  data: data,
                  saving: _saving,
                  dateKey: key,
                  weekdays: _weekdays,
                  months: _months,
                  onToggle: _toggleSlot,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBanner(int offCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: AppSpacing.cardBorderRadius,
      ),
      child: Row(
        children: [
          const Icon(Icons.no_meals_rounded, size: 16, color: AppColors.redAccent),
          const SizedBox(width: 8),
          Text(
            '$offCount day${offCount == 1 ? '' : 's'} fully marked as meal off',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.redAccent),
          ),
        ],
      ),
    );
  }
}

// ── Day card ──────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final DateTime date;
  final _DayData data;
  final Set<String> saving;
  final String dateKey;
  final List<String> weekdays;
  final List<String> months;
  final void Function(DateTime, String) onToggle;

  const _DayCard({
    required this.date,
    required this.data,
    required this.saving,
    required this.dateKey,
    required this.weekdays,
    required this.months,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isAllOff = data.morning == 0 && data.noon == 0 && data.night == 0;
    final weekday = weekdays[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isAllOff ? AppColors.redLight : AppColors.cardBg,
        borderRadius: AppSpacing.cardBorderRadius,
        boxShadow: const [AppSpacing.cardShadow],
        border: isAllOff
            ? Border.all(color: AppColors.redAccent.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Date column
          SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekday,
                  style: AppTextStyles.metaText.copyWith(
                    color: isAllOff ? AppColors.redAccent : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$day $month',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: isAllOff ? AppColors.redAccent : AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Meal toggle chips
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _MealChip(
                  label: 'Morning',
                  isOn: data.morning > 0,
                  isSaving: saving.contains('$dateKey.morning'),
                  onTap: () => onToggle(date, 'morning'),
                ),
                const SizedBox(width: 6),
                _MealChip(
                  label: 'Noon',
                  isOn: data.noon > 0,
                  isSaving: saving.contains('$dateKey.noon'),
                  onTap: () => onToggle(date, 'noon'),
                ),
                const SizedBox(width: 6),
                _MealChip(
                  label: 'Night',
                  isOn: data.night > 0,
                  isSaving: saving.contains('$dateKey.night'),
                  onTap: () => onToggle(date, 'night'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meal toggle chip ──────────────────────────────────────────────────────────

class _MealChip extends StatelessWidget {
  final String label;
  final bool isOn;
  final bool isSaving;
  final VoidCallback onTap;

  const _MealChip({
    required this.label,
    required this.isOn,
    required this.isSaving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isOn ? AppColors.greenLight : AppColors.redLight;
    final fg = isOn ? AppColors.greenAccent : AppColors.redAccent;

    return GestureDetector(
      onTap: isSaving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: isSaving
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOn
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined,
                    size: 12,
                    color: fg,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: AppTextStyles.badgeText.copyWith(
                      color: fg,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _DayData {
  final double morning;
  final double noon;
  final double night;

  const _DayData({
    required this.morning,
    required this.noon,
    required this.night,
  });
}
