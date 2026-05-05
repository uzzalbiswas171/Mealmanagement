import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/models/market_entry_model.dart';
import '../../../data/services/market_service.dart';
import '../../../data/services/meal_service.dart';
import '../../../data/services/member_service.dart';
import '../../chat/screens/chat_screen.dart';
import '../../market/screens/market_screen.dart';
import 'monthly_meal_chart_screen.dart';
import '../../meal_off/screens/meal_off_screen.dart';
import '../../members/screens/members_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../market/widgets/budget_card.dart';
import '../widgets/app_header.dart';
import '../widgets/hero_banner.dart';
import '../widgets/stats_grid.dart';
import '../widgets/meal_tracking_section.dart';
import '../widgets/bottom_summary_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  AppHeaderAction get _headerAction {
    switch (_currentIndex) {
      case 1:
        return AppHeaderAction.profile;
      case 2:
        return AppHeaderAction.search;
      default:
        return AppHeaderAction.bell;
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 1:
        return const MarketScreenBody();
      case 2:
        return const MembersScreenBody();
      case 3:
        return const MealOffScreen();
      case 4:
        return const ChatBody();
      default:
        return const _DashboardBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppHeader(
        action: _headerAction,
        onActionTap: _currentIndex == 1
            ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              )
            : null,
        onAvatarTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      ),
      body: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: _buildBody(),
      ),
      bottomNavigationBar: NavigationBar(
        height: 65,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart_rounded),
            label: 'Market',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Members',
          ),
          NavigationDestination(
            icon: Icon(Icons.no_meals_outlined),
            selectedIcon: Icon(Icons.no_meals_rounded),
            label: 'Meal Off',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
        ],
      ),
    ),
    );
  }
}

// ─── Dynamic Dashboard Body ───────────────────────────────────────────────────

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  StreamSubscription<QuerySnapshot>? _membersSub;
  StreamSubscription<QuerySnapshot>? _marketSub;
  StreamSubscription<QuerySnapshot>? _mealsSub;
  StreamSubscription<QuerySnapshot>? _monthlyMealsSub;
  String? _groupId;

  String _managerName = '';
  String _bazarKariName = '';
  double _totalPaid = 0;
  int _paidCount = 0;
  int _totalMembers = 0;
  double _myMeals = 0;
  double _myPaid = 0;
  int _todayNoon = 0;
  int _todayNight = 0;
  List<Map<String, dynamic>> _todayMealData = [];
  int _pendingMarket = 0;
  double _lastMarketAmount = 0;
  String _lastMarketDate = '';
  double _monthlyMarketTotal = 0;
  int _monthlyMeals = 0;

  double get _mealRate =>
      _monthlyMeals > 0 ? _monthlyMarketTotal / _monthlyMeals : 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gid = context.read<AppState>().groupId;
    if (gid != null && gid != _groupId) {
      _groupId = gid;
      _setupStreams(gid);
    }
  }

  // Called from both stream listeners so stats stay consistent with defaults.
  // Members without a Firestore entry for today default to noon=1, night=1.
  void _computeDayStats() {
    final appState = context.read<AppState>();
    int noon = 0;
    int night = 0;
    final memberIdsWithEntries = <String>{};
    for (final d in _todayMealData) {
      noon += (d['noonMeal'] as num? ?? 0).toInt();
      night += (d['nightMeal'] as num? ?? 0).toInt();
      final mid = d['memberId'] as String?;
      if (mid != null) memberIdsWithEntries.add(mid);
    }
    final missing = _totalMembers - memberIdsWithEntries.length;
    if (missing > 0) {
      noon += missing * appState.defaultNoon;
      night += missing * appState.defaultNight;
    }
    _todayNoon = noon;
    _todayNight = night;
  }

  void _setupStreams(String gid) {
    final myId = context.read<AppState>().userId ?? '';
    // Manager, Bazar Kari, payment totals from members
    _membersSub = MemberService.watchMembers(gid).listen((snap) {
      if (!mounted) return;
      String manager = '';
      String bazarKari = '';
      double paid = 0;
      int paidCount = 0;
      double myMeals = 0;
      double myPaid = 0;
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final role = data['role'] as String? ?? '';
        final displayName = data['displayName'] as String? ?? '';
        final isPaid = data['isPaid'] as bool? ?? false;
        final amount = (data['moneyAmount'] as num?)?.toDouble() ?? 0.0;
        if (role == 'manager') manager = displayName;
        if (role == 'bazarKari') bazarKari = displayName;
        if (isPaid) {
          paid += amount;
          paidCount++;
        }
        if (doc.id == myId) {
          myMeals = (data['mealCount'] as num?)?.toDouble() ?? 0.0;
          myPaid = amount;
        }
      }
      setState(() {
        _managerName = manager;
        _bazarKariName = bazarKari;
        _totalPaid = paid;
        _paidCount = paidCount;
        _totalMembers = snap.docs.length;
        _myMeals = myMeals;
        _myPaid = myPaid;
        _computeDayStats();
      });
    });

    // Market: last entry, pending count, monthly total
    _marketSub = MarketService.watchMarketEntries(gid).listen((snap) {
      if (!mounted) return;
      final entries = snap.docs
          .map((d) => MarketEntry.fromFirestore(d))
          .toList();
      final now = DateTime.now();
      final pending = entries
          .where((e) => e.status == MarketEntryStatus.pending)
          .length;
      final last = entries.isNotEmpty ? entries.first : null;
      final monthTotal = entries
          .where(
            (e) =>
                e.rawDate != null &&
                e.rawDate!.year == now.year &&
                e.rawDate!.month == now.month,
          )
          .fold(0.0, (acc, e) => acc + e.amount);
      setState(() {
        _pendingMarket = pending;
        _lastMarketAmount = last?.amount ?? 0;
        _lastMarketDate = last?.dateLabel ?? '';
        _monthlyMarketTotal = monthTotal;
      });
    });

    // Today's meals
    _mealsSub = MealService.watchMealsForDate(gid, DateTime.now()).listen((snap) {
      if (!mounted) return;
      setState(() {
        _todayMealData = snap.docs
            .map((d) => d.data() as Map<String, dynamic>)
            .toList();
        _computeDayStats();
      });
    });

    // Monthly total meals — used to compute meal rate.
    // For the current month only count entries up to today; future Meal Off
    // entries (created via the Meal Off screen) must not inflate this total.
    final now = DateTime.now();
    final todayCutoff = DateTime(now.year, now.month, now.day + 1);
    _monthlyMealsSub = MealService.watchMealsForMonth(gid, now).listen((snap) {
      if (!mounted) return;
      final total = snap.docs
          .where((d) {
            final ts = (d.data() as Map<String, dynamic>)['entryDate']
                as Timestamp?;
            return ts == null || ts.toDate().isBefore(todayCutoff);
          })
          .fold<int>(
            0,
            (acc, d) =>
                acc +
                ((d.data() as Map<String, dynamic>)['totalMeals'] as num? ?? 0)
                    .toInt(),
          );
      setState(() => _monthlyMeals = total);
    });
  }

  @override
  void dispose() {
    _membersSub?.cancel();
    _marketSub?.cancel();
    _mealsSub?.cancel();
    _monthlyMealsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeroBanner(
                myMeals: _myMeals,
                mealRate: _mealRate,
                myPaid: _myPaid,
              ),
              Padding(
                padding: ResponsiveHelper.screenPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    StatsGrid(
                      managerName: _managerName,
                      bazarKariName: _bazarKariName,
                      todayNoon: _todayNoon,
                      todayNight: _todayNight,
                      pendingMarket: _pendingMarket,
                      lastMarketAmount: _lastMarketAmount,
                      lastMarketDate: _lastMarketDate,
                    ),
                    const SizedBox(height: 20),
                    const MealTrackingSection(),
                    const SizedBox(height: 20),
                    BudgetCard(
                      totalPaid: _totalPaid,
                      totalPending: _totalPaid - _monthlyMarketTotal,
                      paidCount: _paidCount,
                      totalMembers: _totalMembers,
                    ),
                    const SizedBox(height: 20),
                    BottomSummarySection(
                      mealRate: _mealRate,
                      totalCost: _monthlyMarketTotal,
                      monthlyMeals: _monthlyMeals,
                    ),
                    const SizedBox(height: 20),
                    _MonthlyChartCard(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Monthly Meal Chart Card ──────────────────────────────────────────────────

class _MonthlyChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
                 'Jul','Aug','Sep','Oct','Nov','Dec'];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MonthlyMealChartScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.table_chart_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Meal Chart',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${mo[now.month - 1]} ${now.year} — tap to view full table',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white70, size: 24),
          ],
        ),
      ),
    );
  }
}
