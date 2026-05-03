import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/app_state.dart';
import '../../../data/models/meal_entry_model.dart';
import '../../../data/models/member_model.dart';
import '../../../data/services/meal_service.dart';
import '../../../data/services/member_service.dart';
import '../screens/my_meal_history_screen.dart';
import 'edit_meal_sheet.dart';
import 'meal_table.dart';

class MealTrackingSection extends StatefulWidget {
  const MealTrackingSection({super.key});

  @override
  State<MealTrackingSection> createState() => _MealTrackingSectionState();
}

class _MealTrackingSectionState extends State<MealTrackingSection> {
  StreamSubscription<QuerySnapshot>? _membersSub;
  StreamSubscription<QuerySnapshot>? _mealsSub;

  List<MemberProfile> _members = [];
  Map<String, MealEntry> _mealMap = {};
  bool _loading = true;

  final _today = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final groupId = context.read<AppState>().groupId;
    if (groupId != null && _membersSub == null) {
      _membersSub = MemberService.watchMembers(groupId).listen((snap) {
        if (!mounted) return;
        setState(() {
          _members = snap.docs
              .map((d) => MemberProfile.fromFirestore(d))
              .toList();
          _loading = false;
        });
      });

      _mealsSub = MealService.watchMealsForDate(groupId, _today).listen((snap) {
        if (!mounted) return;
        setState(() {
          _mealMap = {
            for (final d in snap.docs)
              (d.data() as Map<String, dynamic>)['memberId'] as String:
                  MealEntry.fromFirestore(d)
          };
        });
      });
    }
  }

  @override
  void dispose() {
    _membersSub?.cancel();
    _mealsSub?.cancel();
    super.dispose();
  }

  List<MealEntry> get _entries {
    final appState = context.read<AppState>();
    return _members.map((m) {
      return _mealMap[m.id] ??
          MealEntry(
            member: Member(id: m.id, name: m.name),
            morningMeal: appState.defaultMorning.toDouble(),
            noonMeal: appState.defaultNoon.toDouble(),
            nightMeal: appState.defaultNight.toDouble(),
          );
    }).toList();
  }

  Map<int, MealEditRecord> get _editRecords {
    final entries = _entries;
    final result = <int, MealEditRecord>{};
    for (int i = 0; i < entries.length; i++) {
      final edit = entries[i].lastEdit;
      if (edit != null) result[i] = edit;
    }
    return result;
  }

  void _showEditSheet(int index) {
    final entry = _entries[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditMealSheet(
        entry: entry,
        onSave: (updated) async {
          final groupId = context.read<AppState>().groupId;
          if (groupId == null) return;
          try {
            await MealService.upsertMeal(
              groupId: groupId,
              memberId: updated.member.id,
              memberName: updated.member.name,
              date: _today,
              morning: updated.morningMeal,
              noon: updated.noonMeal,
              night: updated.nightMeal,
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                '${updated.member.name}\'s meals updated!',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              backgroundColor: AppColors.greenAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ));
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
              backgroundColor: AppColors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ));
          }
        },
      ),
    );
  }

  Future<void> _openCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _today,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyMealHistoryScreen(initialDate: picked),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Meal Tracking', style: AppTextStyles.headingMedium),
            IconButton(
              onPressed: _openCalendar,
              icon: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.primaryBlue,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ))
        else
          MealTable(
            entries: _entries,
            meta: null,
            editRecords: _editRecords,
            onEditTap: _showEditSheet,
            canEditRow: (index) {
              final appState = context.read<AppState>();
              if (appState.role == 'manager') return true;
              return _entries[index].member.id == appState.userId;
            },
          ),
      ],
    );
  }
}
