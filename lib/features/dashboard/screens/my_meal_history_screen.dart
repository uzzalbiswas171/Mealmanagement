import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/app_state.dart';
import '../../../data/services/meal_service.dart';
import '../widgets/meal_badge.dart';

class MyMealHistoryScreen extends StatefulWidget {
  final DateTime initialDate;
  const MyMealHistoryScreen({super.key, required this.initialDate});

  @override
  State<MyMealHistoryScreen> createState() => _MyMealHistoryScreenState();
}

class _MyMealHistoryScreenState extends State<MyMealHistoryScreen> {
  late DateTime _month;
  StreamSubscription<QuerySnapshot>? _sub;
  List<_DayEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.initialDate.year, widget.initialDate.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
  }

  void _subscribe() {
    _sub?.cancel();
    setState(() {
      _loading = true;
      _entries = [];
    });
    final appState = context.read<AppState>();
    final groupId = appState.groupId;
    final userId = appState.userId;
    if (groupId == null || userId == null) return;

    _sub = MealService.watchMealsForMonth(groupId, _month).listen((snap) {
      if (!mounted) return;
      final list = snap.docs
          .where((d) =>
              (d.data() as Map<String, dynamic>)['memberId'] == userId)
          .map((d) {
            final data = d.data() as Map<String, dynamic>;
            final ts = data['entryDate'] as Timestamp?;
            return _DayEntry(
              date: ts?.toDate().toLocal() ?? DateTime.now(),
              morning: (data['morningMeal'] as num?)?.toDouble() ?? 0,
              noon: (data['noonMeal'] as num?)?.toDouble() ?? 0,
              night: (data['nightMeal'] as num?)?.toDouble() ?? 0,
            );
          })
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      setState(() {
        _entries = list;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _prevMonth() {
    setState(() => _month = DateTime(_month.year, _month.month - 1));
    _subscribe();
  }

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1);
    if (next.isAfter(DateTime.now())) return;
    setState(() => _month = next);
    _subscribe();
  }

  bool get _canGoNext {
    final next = DateTime(_month.year, _month.month + 1);
    return next.isBefore(DateTime(DateTime.now().year, DateTime.now().month + 1));
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final totalMeals = _entries.fold(0.0, (s, e) => s + e.total);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _buildAppBar(),
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? _buildEmpty()
                      : _buildList(),
            ),
            if (!_loading && _entries.isNotEmpty) _buildFooter(totalMeals),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 22),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _prevMonth,
                        icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryBlue, size: 26),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_months[_month.month - 1]} ${_month.year}',
                        style: AppTextStyles.headingMedium.copyWith(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: _canGoNext ? _nextMonth : null,
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: _canGoNext ? AppColors.primaryBlue : AppColors.greyBorder,
                          size: 26,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: AppSpacing.cardBorderRadius,
                boxShadow: const [AppSpacing.cardShadow],
              ),
              child: Column(
                children: [
                  _buildTableHeader(),
                  const Divider(height: 1, color: AppColors.greyBorder),
                  ...List.generate(_entries.length, (i) {
                    final e = _entries[i];
                    return Column(
                      children: [
                        _buildRow(e, isEven: i.isEven),
                        if (i < _entries.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF5F5F5)),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
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
          Expanded(flex: 3, child: Text('Date', style: AppTextStyles.tableHeader)),
          Expanded(flex: 2, child: Text('Morning', style: AppTextStyles.tableHeader, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Noon', style: AppTextStyles.tableHeader, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Night', style: AppTextStyles.tableHeader, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Total', style: AppTextStyles.tableHeader, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildRow(_DayEntry e, {required bool isEven}) {
    final day = e.date.day.toString().padLeft(2, '0');
    final mon = _shortMonths[e.date.month - 1];
    return Container(
      color: isEven ? Colors.white : const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('$day $mon', style: AppTextStyles.tableCell),
          ),
          Expanded(flex: 2, child: Center(child: MealBadge(value: e.morning))),
          Expanded(flex: 2, child: Center(child: MealBadge(value: e.noon))),
          Expanded(flex: 2, child: Center(child: MealBadge(value: e.night))),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                _fmt(e.total),
                style: AppTextStyles.tableCell.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(double totalMeals) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.blueSurface,
        borderRadius: AppSpacing.cardBorderRadius,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_rounded, size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                '${_months[_month.month - 1]} Total',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryBlue),
              ),
            ],
          ),
          Text(
            '${_fmt(totalMeals)} meals',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.primaryBlue,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.restaurant_menu_rounded, size: 52, color: AppColors.greyBorder),
          const SizedBox(height: 16),
          Text(
            'No meals recorded',
            style: AppTextStyles.headingSmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'in ${_months[_month.month - 1]} ${_month.year}',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class _DayEntry {
  final DateTime date;
  final double morning;
  final double noon;
  final double night;

  const _DayEntry({
    required this.date,
    required this.morning,
    required this.noon,
    required this.night,
  });

  double get total => morning + noon + night;
}
