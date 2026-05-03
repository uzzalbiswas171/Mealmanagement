import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/models/market_entry_model.dart';
import '../../../data/services/market_service.dart';
import '../../../data/services/member_service.dart';
import '../../../shared/widgets/section_header.dart';
import '../screens/add_market_entry_screen.dart';
import '../widgets/budget_card.dart';
import '../widgets/market_entry_card.dart';
import '../widgets/market_entry_detail_sheet.dart';
import '../widgets/add_entry_cta.dart';

class MarketScreenBody extends StatefulWidget {
  const MarketScreenBody({super.key});

  @override
  State<MarketScreenBody> createState() => _MarketScreenBodyState();
}

class _MarketScreenBodyState extends State<MarketScreenBody> {
  Stream<QuerySnapshot>? _stream;
  StreamSubscription<QuerySnapshot>? _membersSub;
  String? _groupId;

  double _totalPaid = 0;
  int _paidCount = 0;
  int _totalMembers = 0;

  // Selected month for filtering (defaults to current month)
  late DateTime _selectedMonth;

  // Month strip — last 13 months including current
  late final List<DateTime> _months;
  late final ScrollController _monthScroll;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _months = List.generate(13, (i) {
      final m = now.month - 12 + i;
      final y = now.year + ((m - 1) ~/ 12);
      final normalised = ((m - 1) % 12) + 1;
      return DateTime(y, normalised);
    });
    _monthScroll = ScrollController();
    // Scroll to current month after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _scrollToSelected() {
    final idx = _months.indexWhere(
      (m) => m.year == _selectedMonth.year && m.month == _selectedMonth.month,
    );
    if (idx < 0 || !_monthScroll.hasClients) return;
    const chipW = 76.0; // approximate chip width + spacing
    _monthScroll.animateTo(
      (idx * chipW).clamp(0.0, _monthScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gid = context.read<AppState>().groupId;
    if (gid != null && gid != _groupId) {
      _groupId = gid;
      _stream = MarketService.watchMarketEntries(gid);
      _membersSub?.cancel();
      _membersSub = MemberService.watchMembers(gid).listen((snap) {
        if (!mounted) return;
        double paid = 0;
        int paidCount = 0;
        for (final doc in snap.docs) {
          final d = doc.data() as Map<String, dynamic>;
          final isPaid = d['isPaid'] as bool? ?? false;
          final amount = (d['moneyAmount'] as num?)?.toDouble() ?? 0.0;
          if (isPaid) {
            paid += amount;
            paidCount++;
          }
        }
        setState(() {
          _totalPaid = paid;
          _paidCount = paidCount;
          _totalMembers = snap.docs.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _membersSub?.cancel();
    _monthScroll.dispose();
    super.dispose();
  }

  bool _inSelectedMonth(MarketEntry e) {
    if (e.rawDate == null) return false;
    return e.rawDate!.year == _selectedMonth.year &&
        e.rawDate!.month == _selectedMonth.month;
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.screenPadding(context);

    if (_stream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        final allEntries = snapshot.data?.docs
                .map((d) => MarketEntry.fromFirestore(d))
                .toList() ??
            [];

        // Filter to selected month
        final entries =
            allEntries.where(_inSelectedMonth).toList();

        final bazarTotal =
            entries.fold(0.0, (acc, e) => acc + e.amount);

        return Column(
          children: [
            // ── Month selector strip ─────────────────────────────
            _buildMonthStrip(),
            // ── Scrollable content ───────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: padding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildSearchBar(),
                          const SizedBox(height: 16),
                          // Show budget card only for current month
                          if (_isCurrentMonth)
                            BudgetCard(
                              totalPaid: _totalPaid,
                              totalPending: _totalPaid - bazarTotal,
                              paidCount: _paidCount,
                              totalMembers: _totalMembers,
                            )
                          else
                            _buildMonthSummaryCard(bazarTotal),
                          const SizedBox(height: 24),
                          SectionHeader(
                            title: 'Bazar Kari — ${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                            actionText: '',
                            onAction: null,
                          ),
                          const SizedBox(height: 12),
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Center(
                                child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ))
                          else if (entries.isEmpty)
                            _buildEmptyState()
                          else
                            ...entries.map((e) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 14),
                                  child: MarketEntryCard(
                                    entry: e,
                                    onTap: () => showMarketEntryDetail(
                                      context: context,
                                      entry: e,
                                      groupId: _groupId ?? '',
                                    ),
                                  ),
                                )),
                          const SizedBox(height: 10),
                          if (['manager', 'bazarKari'].contains(context.watch<AppState>().role))
                            AddEntryCta(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AddMarketEntryScreen(),
                                ),
                              ),
                            ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Month strip ──────────────────────────────────────────────────────────────

  Widget _buildMonthStrip() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          controller: _monthScroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: _months.length,
          itemBuilder: (context, i) {
            final m = _months[i];
            final isSelected = m.year == _selectedMonth.year &&
                m.month == _selectedMonth.month;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedMonth = m;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : AppColors.greySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_monthNames[m.month - 1]} ${m.year}',
                  style: AppTextStyles.badgeText.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Month summary card (past months) ─────────────────────────────────────────

  Widget _buildMonthSummaryCard(double bazarTotal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year} — Total Spent',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '৳ ${bazarTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(50),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 1)),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search বাজার করি history...',
          hintStyle: AppTextStyles.bodySmall.copyWith(fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textSecondary, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No entries for ${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
              style: AppTextStyles.headingSmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _isCurrentMonth
                  ? 'Add a market entry using the button below'
                  : 'No market trips were recorded this month',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
