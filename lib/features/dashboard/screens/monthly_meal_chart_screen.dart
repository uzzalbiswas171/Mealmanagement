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
import '../widgets/edit_meal_sheet.dart';

class MonthlyMealChartScreen extends StatefulWidget {
  const MonthlyMealChartScreen({super.key});

  @override
  State<MonthlyMealChartScreen> createState() =>
      _MonthlyMealChartScreenState();
}

class _MonthlyMealChartScreenState extends State<MonthlyMealChartScreen> {
  static const _dateColW = 72.0;
  static const _memberColW = 120.0;
  static const _rowH = 46.0;
  static const _headerH = 58.0;

  late DateTime _month;
  late final List<DateTime> _months;

  StreamSubscription<QuerySnapshot>? _membersSub;
  StreamSubscription<QuerySnapshot>? _mealsSub;

  List<({String id, String name})> _members = [];
  // key: "memberId_day" → {morning, noon, night}
  Map<String, ({double m, double noon, double night})> _cellData = {};

  final _hBodyCtrl = ScrollController();
  final _hHeadCtrl = ScrollController();
  final _vCtrl = ScrollController();

  String? _groupId;
  bool _loadingMeals = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _months = List.generate(13, (i) {
      final m = now.month - 12 + i;
      final y = now.year + ((m - 1) ~/ 12);
      return DateTime(y, ((m - 1) % 12) + 1);
    });
    _hBodyCtrl.addListener(() {
      if (_hHeadCtrl.hasClients &&
          (_hHeadCtrl.offset - _hBodyCtrl.offset).abs() > 0.5) {
        _hHeadCtrl.jumpTo(_hBodyCtrl.offset);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gid = context.read<AppState>().groupId;
    if (gid != null && gid != _groupId) {
      _groupId = gid;
      _subscribeMembers(gid);
      _subscribeMeals(gid);
    }
  }

  void _subscribeMembers(String gid) {
    _membersSub?.cancel();
    _membersSub = MemberService.watchMembers(gid).listen((snap) {
      if (!mounted) return;
      final list = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return (
          id: d.id,
          name: data['displayName'] as String? ?? 'Member',
        );
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      setState(() => _members = list);
    });
  }

  void _subscribeMeals(String gid) {
    _mealsSub?.cancel();
    setState(() => _loadingMeals = true);
    _mealsSub = MealService.watchMealsForMonth(gid, _month).listen((snap) {
      if (!mounted) return;
      final map = <String, ({double m, double noon, double night})>{};
      for (final doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final memberId = d['memberId'] as String? ?? '';
        final ts = d['entryDate'] as Timestamp?;
        if (memberId.isEmpty || ts == null) continue;
        final day = ts.toDate().toLocal().day;
        map['${memberId}_$day'] = (
          m: (d['morningMeal'] as num?)?.toDouble() ?? 0,
          noon: (d['noonMeal'] as num?)?.toDouble() ?? 0,
          night: (d['nightMeal'] as num?)?.toDouble() ?? 0,
        );
      }
      setState(() {
        _cellData = map;
        _loadingMeals = false;
      });
    });
  }

  void _changeMonth(DateTime m) {
    _month = m;
    if (_groupId != null) _subscribeMeals(_groupId!);
  }

  @override
  void dispose() {
    _membersSub?.cancel();
    _mealsSub?.cancel();
    _hBodyCtrl.dispose();
    _hHeadCtrl.dispose();
    _vCtrl.dispose();
    super.dispose();
  }

  int get _daysInMonth =>
      DateTime(_month.year, _month.month + 1, 0).day;

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _dayLabel(int day) {
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
                 'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '$day ${mo[_month.month - 1]}';
  }

  void _openEdit(int day, String memberId, String memberName) {
    final appState = context.read<AppState>();
    final isManager = appState.role == 'manager';
    if (!isManager) return;

    final key = '${memberId}_$day';
    final existing = _cellData[key];
    final entry = MealEntry(
      member: Member(id: memberId, name: memberName),
      morningMeal: existing?.m ?? appState.defaultMorning.toDouble(),
      noonMeal: existing?.noon ?? appState.defaultNoon.toDouble(),
      nightMeal: existing?.night ?? appState.defaultNight.toDouble(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditMealSheet(
        entry: entry,
        onSave: (updated) async {
          final date = DateTime(_month.year, _month.month, day);
          await MealService.upsertMeal(
            groupId: _groupId!,
            memberId: memberId,
            memberName: memberName,
            date: date,
            morning: updated.morningMeal,
            noon: updated.noonMeal,
            night: updated.nightMeal,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isManager = appState.role == 'manager';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildMonthStrip(),
          if (_loadingMeals || _members.isEmpty)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(child: _buildTable(isManager, appState.userId ?? '')),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    const mo = ['January','February','March','April','May','June',
                 'July','August','September','October','November','December'];
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
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary, size: 22),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Meal Chart — ${mo[_month.month - 1]} ${_month.year}',
                    style: AppTextStyles.appBarTitle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthStrip() {
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
                 'Jul','Aug','Sep','Oct','Nov','Dec'];
    return Container(
      height: 52,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _months.length,
        itemBuilder: (_, i) {
          final m = _months[i];
          final selected = m.year == _month.year && m.month == _month.month;
          return GestureDetector(
            onTap: () => setState(() => _changeMonth(m)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryBlue : AppColors.blueSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${mo[m.month - 1]} ${m.year}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.primaryBlue,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTable(bool isManager, String userId) {
    final totalDataW = _members.length * _memberColW;

    return Column(
      children: [
        // ── Sticky header ──
        Container(
          color: const Color(0xFFF8F9FA),
          child: Row(
            children: [
              // date column header
              SizedBox(
                width: _dateColW,
                height: _headerH,
                child: Center(
                  child: Text('Date',
                      style: AppTextStyles.tableHeader
                          .copyWith(color: AppColors.primaryBlue)),
                ),
              ),
              Container(width: 1, height: _headerH, color: const Color(0xFFE8EAF0)),
              // member headers (horizontal scroll synced with body)
              Expanded(
                child: SingleChildScrollView(
                  controller: _hHeadCtrl,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: totalDataW,
                    height: _headerH,
                    child: Row(
                      children: _members.map((m) => SizedBox(
                        width: _memberColW,
                        height: _headerH,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              m.name.length > 10
                                  ? '${m.name.substring(0, 9)}…'
                                  : m.name,
                              style: AppTextStyles.tableHeader
                                  .copyWith(color: AppColors.textPrimary, fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              height: 1.5,
                              width: 40,
                              color: AppColors.primaryBlue,
                              margin: const EdgeInsets.only(bottom: 3),
                            ),
                            Text(
                              'm  noon  night',
                              style: AppTextStyles.metaText.copyWith(fontSize: 9),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ),
              // edit col header
              SizedBox(
                width: 40,
                height: _headerH,
                child: Center(
                  child: Text('Edit',
                      style: AppTextStyles.tableHeader
                          .copyWith(color: AppColors.primaryBlue)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE0E4EF)),

        // ── Scrollable body ──
        Expanded(
          child: SingleChildScrollView(
            controller: _vCtrl,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date column (fixed)
                SizedBox(
                  width: _dateColW,
                  child: Column(
                    children: List.generate(_daysInMonth, (i) {
                      final day = i + 1;
                      final isToday = DateTime.now().year == _month.year &&
                          DateTime.now().month == _month.month &&
                          DateTime.now().day == day;
                      return _DateCell(
                        label: _dayLabel(day),
                        isToday: isToday,
                        height: _rowH,
                        isLast: day == _daysInMonth,
                      );
                    }),
                  ),
                ),
                Container(width: 1, color: const Color(0xFFE8EAF0)),

                // Data cells (horizontal scroll)
                Expanded(
                  child: SingleChildScrollView(
                    controller: _hBodyCtrl,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: totalDataW,
                      child: Column(
                        children: List.generate(_daysInMonth, (i) {
                          final day = i + 1;
                          return SizedBox(
                            height: _rowH,
                            child: Row(
                              children: _members.map((m) {
                                final key = '${m.id}_$day';
                                final cell = _cellData[key];
                                final mv = cell?.m ?? appState.defaultMorning.toDouble();
                                final nv = cell?.noon ?? appState.defaultNoon.toDouble();
                                final ntv = cell?.night ?? appState.defaultNight.toDouble();
                                final hasData = _cellData.containsKey(key);
                                return SizedBox(
                                  width: _memberColW,
                                  height: _rowH,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: const Color(0xFFF0F2F8), width: day < _daysInMonth ? 1 : 0),
                                        right: const BorderSide(color: Color(0xFFF0F2F8)),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _ValChip(val: _fmt(mv), hasData: hasData),
                                        _ValChip(val: _fmt(nv), hasData: hasData),
                                        _ValChip(val: _fmt(ntv), hasData: hasData),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),

                // Edit column
                SizedBox(
                  width: 40,
                  child: Column(
                    children: List.generate(_daysInMonth, (i) {
                      final day = i + 1;
                      return SizedBox(
                        height: _rowH,
                        child: Center(
                          child: isManager
                              ? GestureDetector(
                                  onTap: () => _showDayEditMenu(day, isManager, userId),
                                  child: const Icon(Icons.edit_outlined,
                                      size: 16, color: AppColors.textSecondary),
                                )
                              : const SizedBox.shrink(),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  AppState get appState => context.read<AppState>();

  void _showDayEditMenu(int day, bool isManager, String userId) {
    final editableMembers = isManager
        ? _members
        : _members.where((m) => m.id == userId).toList();

    if (editableMembers.isEmpty) return;
    if (editableMembers.length == 1) {
      _openEdit(day, editableMembers.first.id, editableMembers.first.name);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Edit meals for ${_dayLabel(day)}',
                      style: AppTextStyles.headingMedium),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.only(bottom: 32),
                  children: editableMembers.map((m) => ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.blueSurface,
                      child: Text(
                        m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ),
                    title: Text(m.name, style: AppTextStyles.tableCell),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openEdit(day, m.id, m.name);
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Date cell ─────────────────────────────────────────────────────────────────

class _DateCell extends StatelessWidget {
  final String label;
  final bool isToday;
  final double height;
  final bool isLast;

  const _DateCell({
    required this.label,
    required this.isToday,
    required this.height,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isToday ? AppColors.blueSurface : Colors.transparent,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF0F2F8)),
              ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.metaText.copyWith(
          color: isToday ? AppColors.primaryBlue : AppColors.textSecondary,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Value chip ────────────────────────────────────────────────────────────────

class _ValChip extends StatelessWidget {
  final String val;
  final bool hasData;

  const _ValChip({required this.val, required this.hasData});

  @override
  Widget build(BuildContext context) {
    return Text(
      val,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: hasData ? FontWeight.w600 : FontWeight.w400,
        color: hasData ? AppColors.textPrimary : AppColors.textSecondary,
      ),
    );
  }
}
