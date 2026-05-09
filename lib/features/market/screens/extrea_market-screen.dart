import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/app_state.dart';
import '../../../data/models/extra_market_entry_model.dart';
import '../../../data/services/extra_market_service.dart';

class ExtraMarketScreen extends StatefulWidget {
  const ExtraMarketScreen({super.key});

  @override
  State<ExtraMarketScreen> createState() => _ExtraMarketScreenState();
}

class _ExtraMarketScreenState extends State<ExtraMarketScreen> {
  StreamSubscription<QuerySnapshot>? _sub;
  List<ExtraMarketEntry> _allEntries = [];
  bool _loading = true;
  String? _groupId;

  late DateTime _selectedMonth;
  late final List<DateTime> _months;
  late final ScrollController _monthScroll;

  static const _monthNames = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _months = List.generate(13, (i) {
      final m = now.month - 12 + i;
      final y = now.year + ((m - 1) ~/ 12);
      return DateTime(y, ((m - 1) % 12) + 1);
    });
    _monthScroll = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _scrollToSelected() {
    final idx = _months.indexWhere(
      (m) => m.year == _selectedMonth.year && m.month == _selectedMonth.month,
    );
    if (idx < 0 || !_monthScroll.hasClients) return;
    _monthScroll.animateTo(
      (idx * 80.0).clamp(0.0, _monthScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gid = context.read<AppState>().groupId;
    if (gid != null && gid != _groupId) {
      _groupId = gid;
      _sub?.cancel();
      _sub = ExtraMarketService.watchEntries(gid).listen((snap) {
        if (!mounted) return;
        setState(() {
          _allEntries = snap.docs
              .map((d) => ExtraMarketEntry.fromFirestore(d))
              .toList();
          _loading = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _monthScroll.dispose();
    super.dispose();
  }

  List<ExtraMarketEntry> get _filtered => _allEntries.where((e) {
        final d = e.date ?? e.createdAt;
        return d.year == _selectedMonth.year && d.month == _selectedMonth.month;
      }).toList();

  double get _monthTotal =>
      _filtered.fold(0.0, (acc, e) => acc + e.amount);

  String _fmtAmount(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  String _dateLabel(DateTime dt) {
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
                 'Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return '${dt.day} ${mo[dt.month - 1]}';
  }

  void _showSheet({ExtraMarketEntry? entry}) {
    final appState = context.read<AppState>();
    final myId = appState.userId ?? '';
    final isManager = appState.isManager;
    final canEdit = entry == null ||
        entry.addedBy == myId ||
        isManager;
    final canDelete = entry != null &&
        (entry.addedBy == myId || isManager);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditSheet(
        entry: entry,
        groupId: _groupId ?? '',
        userId: myId,
        userName: appState.displayName ?? 'User',
        canEdit: canEdit,
        canDelete: canDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSheet(),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          _buildMonthStrip(),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {},
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(filtered.length),
                      const SizedBox(height: 20),
                      if (filtered.isEmpty)
                        _buildEmpty()
                      else ...[
                        Text(
                          'ENTRIES — ${_monthNames[_selectedMonth.month - 1].toUpperCase()} ${_selectedMonth.year}',
                          style: AppTextStyles.tableHeader.copyWith(
                              color: AppColors.primaryBlue, letterSpacing: 0.6),
                        ),
                        const SizedBox(height: 12),
                        ...filtered.map((e) => _EntryCard(
                              entry: e,
                              fmtAmount: _fmtAmount,
                              dateLabel: _dateLabel,
                              onTap: () => _showSheet(entry: e),
                            )),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(
                color: Color(0x12000000),
                blurRadius: 4,
                offset: Offset(0, 2))],
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
                  const Icon(Icons.add_shopping_cart_rounded,
                      size: 20, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Text('Extra Market', style: AppTextStyles.appBarTitle),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildMonthStrip() => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
          height: 36,
          child: ListView.builder(
            controller: _monthScroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _months.length,
            itemBuilder: (_, i) {
              final m = _months[i];
              final selected = m.year == _selectedMonth.year &&
                  m.month == _selectedMonth.month;
              return GestureDetector(
                onTap: () => setState(() => _selectedMonth = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFE65100)
                        : AppColors.greySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_monthNames[m.month - 1]} ${m.year}',
                    style: AppTextStyles.badgeText.copyWith(
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

  Widget _buildSummaryCard(int count) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFBF360C), Color(0xFFE64A19)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE65100).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Extra Market — ${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '৳ ${_fmtAmount(_monthTotal)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count == 0
                        ? 'No entries this month'
                        : '$count ${count == 1 ? 'entry' : 'entries'} this month',
                    style: AppTextStyles.metaText.copyWith(
                        color: Colors.white.withValues(alpha: 0.7)),
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
              child: const Icon(Icons.add_shopping_cart_rounded,
                  color: Colors.white, size: 24),
            ),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Column(
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  size: 56, color: AppColors.greyBorder),
              const SizedBox(height: 12),
              Text(
                'No extra market entries',
                style: AppTextStyles.headingSmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap + to add an entry',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
}

// ── Entry Card ────────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final ExtraMarketEntry entry;
  final String Function(double) fmtAmount;
  final String Function(DateTime) dateLabel;
  final VoidCallback onTap;

  const _EntryCard({
    required this.entry,
    required this.fmtAmount,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayDate = entry.date ?? entry.createdAt;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [AppSpacing.cardShadow],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Orange left accent bar
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFE65100),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.title,
                              style: AppTextStyles.headingSmall
                                  .copyWith(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '৳${fmtAmount(entry.amount)}',
                            style: AppTextStyles.headingSmall.copyWith(
                              color: const Color(0xFFE65100),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(dateLabel(displayDate),
                              style: AppTextStyles.metaText),
                          const SizedBox(width: 12),
                          const Icon(Icons.person_outline_rounded,
                              size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              entry.addedByName,
                              style: AppTextStyles.metaText,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (entry.notes != null &&
                          entry.notes!.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          entry.notes!,
                          style: AppTextStyles.metaText.copyWith(
                              fontStyle: FontStyle.italic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add / Edit Sheet ──────────────────────────────────────────────────────────

class _AddEditSheet extends StatefulWidget {
  final ExtraMarketEntry? entry;
  final String groupId;
  final String userId;
  final String userName;
  final bool canEdit;
  final bool canDelete;

  const _AddEditSheet({
    required this.entry,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.canEdit,
    required this.canDelete,
  });

  @override
  State<_AddEditSheet> createState() => _AddEditSheetState();
}

class _AddEditSheetState extends State<_AddEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  DateTime? _date;
  bool _saving = false;
  bool _deleting = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(
        text: e != null
            ? (e.amount == e.amount.truncateToDouble()
                ? e.amount.toInt().toString()
                : e.amount.toStringAsFixed(2))
            : '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _date = e?.date ?? e?.createdAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFFE65100)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final missingFields = <String>[];
    if (_titleCtrl.text.trim().isEmpty) missingFields.add('Item / Description');
    if (_amountCtrl.text.trim().isEmpty) missingFields.add('Amount');

    if (_formKey.currentState?.validate() != true) {
      if (missingFields.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Please fill: ${missingFields.join(', ')}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: AppColors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ));
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final title = _titleCtrl.text.trim();
      final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
      final notes = _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim();

      if (_isEditing) {
        await ExtraMarketService.updateEntry(
          groupId: widget.groupId,
          entryId: widget.entry!.id,
          title: title,
          amount: amount,
          date: _date,
          notes: notes,
        );
      } else {
        await ExtraMarketService.addEntry(
          groupId: widget.groupId,
          addedBy: widget.userId,
          addedByName: widget.userName,
          title: title,
          amount: amount,
          date: _date,
          notes: notes,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          _isEditing ? 'Entry updated!' : '"$title" added!',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: AppColors.greenAccent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: AppColors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Delete this extra market entry? Cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ExtraMarketService.deleteEntry(
        groupId: widget.groupId,
        entryId: widget.entry!.id,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: AppColors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
  );
  static final _focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFFE65100), width: 1.5),
  );
  static final _errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.redAccent),
  );

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall,
        prefixIcon:
            Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: widget.canEdit
            ? AppColors.scaffoldBg
            : AppColors.greySurface,
        border: _border,
        enabledBorder: _border,
        focusedBorder: _focusedBorder,
        errorBorder: _errorBorder,
        focusedErrorBorder: _errorBorder,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );

  String get _dateText {
    if (_date == null) return 'Select Date';
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
                 'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${_date!.day} ${mo[_date!.month - 1]} ${_date!.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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

              // Header
              Row(
                children: [
                  const Icon(Icons.add_shopping_cart_rounded,
                      size: 20, color: Color(0xFFE65100)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Entry' : 'Add Extra Market',
                      style: AppTextStyles.headingMedium
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (widget.canEdit)
                    TextButton(
                      onPressed: _saving ? null : _save,
                      child: Text(
                        'Save',
                        style: AppTextStyles.headingSmall
                            .copyWith(color: const Color(0xFFE65100)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Form card
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
                    Text('DETAILS',
                        style: AppTextStyles.tableHeader.copyWith(
                            color: const Color(0xFFE65100),
                            letterSpacing: 0.6)),
                    const SizedBox(height: 14),

                    // Title
                    TextFormField(
                      controller: _titleCtrl,
                      enabled: widget.canEdit,
                      style: AppTextStyles.tableCell,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true)
                              ? 'Title is required'
                              : null,
                      decoration: _dec('Item / Description',
                          Icons.label_outline_rounded),
                    ),
                    const SizedBox(height: 12),

                    // Amount
                    TextFormField(
                      controller: _amountCtrl,
                      enabled: widget.canEdit,
                      style: AppTextStyles.tableCell,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (v) {
                        if (v?.trim().isEmpty ?? true) {
                          return 'Amount is required';
                        }
                        if ((double.tryParse(v!.trim()) ?? -1) < 0) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                      decoration:
                          _dec('Amount (৳)', Icons.currency_exchange_rounded),
                    ),
                    const SizedBox(height: 12),

                    // Date picker
                    GestureDetector(
                      onTap: widget.canEdit ? _pickDate : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: widget.canEdit
                              ? AppColors.scaffoldBg
                              : AppColors.greySurface,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 20,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Text(
                              _dateText,
                              style: AppTextStyles.tableCell.copyWith(
                                color: _date != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right_rounded,
                                size: 18,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextFormField(
                      controller: _notesCtrl,
                      enabled: widget.canEdit,
                      style: AppTextStyles.tableCell,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        labelStyle: AppTextStyles.bodySmall,
                        prefixIcon: const Padding(
                          padding:
                              EdgeInsets.only(left: 12, right: 8, top: 12),
                          child: Icon(Icons.notes_rounded,
                              size: 20, color: AppColors.textSecondary),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                            minWidth: 0, minHeight: 0),
                        filled: true,
                        fillColor: widget.canEdit
                            ? AppColors.scaffoldBg
                            : AppColors.greySurface,
                        border: _border,
                        enabledBorder: _border,
                        focusedBorder: _focusedBorder,
                        contentPadding: const EdgeInsets.fromLTRB(
                            0, 14, 12, 14),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Save button
              if (widget.canEdit)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(_isEditing
                            ? Icons.check_rounded
                            : Icons.add_shopping_cart_rounded,
                            size: 20),
                    label: Text(
                      _isEditing ? 'Save Changes' : 'Add Entry',
                      style: AppTextStyles.headingSmall.copyWith(
                          color: Colors.white, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),

              // Delete button
              if (widget.canDelete) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _deleting ? null : _delete,
                    icon: _deleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.redAccent))
                        : const Icon(Icons.delete_outline_rounded,
                            size: 18),
                    label: Text('Delete Entry',
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.redAccent,
                      side: const BorderSide(color: AppColors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],

              // Read-only notice
              if (!widget.canEdit)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'You can only edit your own entries',
                      style: AppTextStyles.metaText
                          .copyWith(color: AppColors.textSecondary),
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
