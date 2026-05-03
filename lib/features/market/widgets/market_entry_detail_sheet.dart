import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/app_state.dart';
import '../../../data/models/market_entry_model.dart';
import '../../../data/services/market_service.dart';
import '../screens/edit_market_entry_screen.dart';

void showMarketEntryDetail({
  required BuildContext context,
  required MarketEntry entry,
  required String groupId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MarketEntryDetailSheet(entry: entry, groupId: groupId),
  );
}

class _MarketEntryDetailSheet extends StatefulWidget {
  final MarketEntry entry;
  final String groupId;

  const _MarketEntryDetailSheet({
    required this.entry,
    required this.groupId,
  });

  @override
  State<_MarketEntryDetailSheet> createState() =>
      _MarketEntryDetailSheetState();
}

class _MarketEntryDetailSheetState extends State<_MarketEntryDetailSheet> {
  Future<void> _openEdit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditMarketEntryScreen(
          entry: widget.entry,
          groupId: widget.groupId,
        ),
      ),
    );
    if (saved == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isManager = context.read<AppState>().role == 'manager';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    _buildHeader(isManager),
                    const SizedBox(height: 20),
                    _buildItemsSection(),
                    if (widget.entry.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      _buildNotesSection(),
                    ],
                    const SizedBox(height: 16),
                    if (widget.entry.createdByName.isNotEmpty)
                      _buildMetaRow(
                        Icons.person_outline_rounded,
                        'Made by',
                        widget.entry.createdByName,
                      ),
                    const SizedBox(height: 4),
                    _buildMetaRow(
                      Icons.verified_outlined,
                      'Verification',
                      widget.entry.verifiedLabel,
                    ),
                    if (widget.entry.lastEditedByName != null) ...[
                      const SizedBox(height: 4),
                      _buildMetaRow(
                        Icons.edit_outlined,
                        'Last edited by',
                        '${widget.entry.lastEditedByName}${widget.entry.lastEditedAt != null ? ' • ${_fmtDate(widget.entry.lastEditedAt!)}' : ''}',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.entry.title,
                style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
              ),
            ),
            if (isManager)
              IconButton(
                onPressed: _openEdit,
                icon: const Icon(Icons.edit_rounded,
                    color: AppColors.primaryBlue, size: 20),
                tooltip: 'Edit entry',
                padding: const EdgeInsets.all(4),
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            const SizedBox(width: 4),
            _StatusBadge(status: widget.entry.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(widget.entry.dateLabel, style: AppTextStyles.metaText),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Text(
                widget.entry.formattedAmount,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    return StreamBuilder(
      stream:
          MarketService.watchMarketItems(widget.groupId, widget.entry.id),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final items = docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return (
            name: data['name'] as String? ?? '—',
            quantity: data['quantity'] as String? ?? '',
            amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_basket_outlined,
                    size: 16, color: AppColors.primaryBlue),
                const SizedBox(width: 6),
                Text(
                  'Items Purchased',
                  style: AppTextStyles.headingSmall
                      .copyWith(color: AppColors.primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                      flex: 5,
                      child: Text('Item Name',
                          style: AppTextStyles.tableHeader)),
                  Expanded(
                      flex: 2,
                      child: Text('Qty',
                          style: AppTextStyles.tableHeader,
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 3,
                      child: Text('Price',
                          style: AppTextStyles.tableHeader,
                          textAlign: TextAlign.right)),
                ],
              ),
            ),
            if (snapshot.connectionState == ConnectionState.waiting &&
                items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No items recorded',
                      style: AppTextStyles.metaText),
                ),
              )
            else
              ...items.asMap().entries.map((e) {
                final item = e.value;
                final isLast = e.key == items.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(item.name,
                                style: AppTextStyles.tableCell),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.quantity.isEmpty
                                  ? '—'
                                  : item.quantity,
                              style: AppTextStyles.tableCell.copyWith(
                                  color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.amount > 0
                                  ? '৳ ${item.amount.toStringAsFixed(2)}'
                                  : '—',
                              style: AppTextStyles.tableCell.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                          height: 1,
                          indent: 12,
                          endIndent: 12,
                          color: Color(0xFFF0F0F0)),
                  ],
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sticky_note_2_outlined,
                size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text('Notes',
                style: AppTextStyles.headingSmall
                    .copyWith(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDE7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFEE58)),
          ),
          child: Text(
            widget.entry.notes!,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF795548),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('$label: ', style: AppTextStyles.metaText),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.metaText
                  .copyWith(color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime dt) {
    const mo = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day.toString().padLeft(2, '0')} ${mo[dt.month - 1]}, $h:$m $period';
  }
}

class _StatusBadge extends StatelessWidget {
  final MarketEntryStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case MarketEntryStatus.completed:
        bg = AppColors.greenLight;
        fg = AppColors.greenAccent;
      case MarketEntryStatus.archived:
        bg = const Color(0xFFEEEEEE);
        fg = AppColors.textSecondary;
      case MarketEntryStatus.pending:
        bg = AppColors.redLight;
        fg = AppColors.redAccent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.badgeText.copyWith(color: fg),
      ),
    );
  }
}
