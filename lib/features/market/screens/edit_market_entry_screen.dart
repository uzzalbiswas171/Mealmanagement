import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/market_entry_model.dart';
import '../../../data/services/market_service.dart';

class EditMarketEntryScreen extends StatefulWidget {
  final MarketEntry entry;
  final String groupId;

  const EditMarketEntryScreen({
    super.key,
    required this.entry,
    required this.groupId,
  });

  @override
  State<EditMarketEntryScreen> createState() => _EditMarketEntryScreenState();
}

class _EditMarketEntryScreenState extends State<EditMarketEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  DateTime? _dateTime;
  late MarketEntryStatus _status;

  bool _loadingItems = true;
  bool _saving = false;
  List<Map<String, dynamic>> _initialItems = [];

  final _itemsKey = GlobalKey<_EditItemsSectionState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _amountController =
        TextEditingController(text: widget.entry.amount.toStringAsFixed(2));
    _notesController =
        TextEditingController(text: widget.entry.notes ?? '');
    _dateTime = widget.entry.rawDate;
    _status = widget.entry.status;
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await MarketService.getMarketItems(
        widget.groupId, widget.entry.id);
    if (!mounted) return;
    setState(() {
      _initialItems = items;
      _loadingItems = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime ?? DateTime.now()),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primaryBlue),
        ),
        child: child!,
      ),
    );
    setState(() {
      _dateTime = DateTime(
        date.year, date.month, date.day,
        time?.hour ?? 0, time?.minute ?? 0,
      );
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_itemsKey.currentState?.validate() != true) return;

    final items = _itemsKey.currentState!.getItems();
    final total =
        double.tryParse(_amountController.text.trim()) ?? 0.0;

    setState(() => _saving = true);
    try {
      await MarketService.updateFullEntry(
        groupId: widget.groupId,
        entryId: widget.entry.id,
        title: _titleController.text.trim(),
        totalAmount: total,
        tripDate: _dateTime,
        status: _status.name,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        items: items,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Entry updated successfully!',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenAccent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.pop(context, true); // true = saved
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(),
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
        backgroundColor: AppColors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _buildAppBar(),
      body: _loadingItems
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          _FormSection(
                            title: 'TRIP DETAILS',
                            children: [
                              _InputField(
                                controller: _titleController,
                                label: 'Trip Title',
                                icon: Icons.storefront_outlined,
                                validator: (v) =>
                                    (v?.trim().isEmpty ?? true)
                                        ? 'Title is required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              _InputField(
                                controller: _amountController,
                                label: 'Total Amount',
                                icon: Icons.attach_money_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                validator: (v) =>
                                    (v?.trim().isEmpty ?? true)
                                        ? 'Amount is required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              _DateTimeField(
                                dateTime: _dateTime,
                                onTap: _pickDateTime,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _FormSection(
                            title: 'ITEMS PURCHASED',
                            children: [
                              _EditItemsSection(
                                key: _itemsKey,
                                initialItems: _initialItems,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _FormSection(
                            title: 'ENTRY STATUS',
                            children: [
                              _StatusSelector(
                                selected: _status,
                                onChanged: (s) =>
                                    setState(() => _status = s),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _FormSection(
                            title: 'NOTES',
                            children: [
                              _NotesField(
                                  controller: _notesController),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _SaveButton(
                              onTap: _saving ? () {} : _submit,
                              saving: _saving),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
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
          boxShadow: [
            BoxShadow(
                color: Color(0x12000000),
                blurRadius: 4,
                offset: Offset(0, 2))
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 4, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary, size: 22),
                ),
                const SizedBox(width: 4),
                Text('Edit Market Entry',
                    style: AppTextStyles.appBarTitle),
                const Spacer(),
                TextButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(
                    'Save',
                    style: AppTextStyles.headingSmall
                        .copyWith(color: AppColors.primaryBlue),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Form Section ─────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            title,
            style: AppTextStyles.tableHeader.copyWith(
              letterSpacing: 0.6,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ─── Input Field ──────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
  });

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
  );
  static final _focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide:
        const BorderSide(color: AppColors.primaryBlue, width: 1.5),
  );
  static final _errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.redAccent),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppTextStyles.tableCell,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall,
        prefixIcon:
            Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.scaffoldBg,
        border: _border,
        enabledBorder: _border,
        focusedBorder: _focusedBorder,
        errorBorder: _errorBorder,
        focusedErrorBorder: _errorBorder,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
      ),
    );
  }
}

// ─── Date+Time Field ──────────────────────────────────────────────────────────

class _DateTimeField extends StatelessWidget {
  final DateTime? dateTime;
  final VoidCallback onTap;
  const _DateTimeField({required this.dateTime, required this.onTap});

  String get _label {
    if (dateTime == null) return 'Select Date & Time';
    final d = dateTime!;
    final h =
        d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day.toString().padLeft(2, '0')} / '
        '${d.month.toString().padLeft(2, '0')} / '
        '${d.year}  •  $h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = dateTime != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              _label,
              style: AppTextStyles.tableCell.copyWith(
                color: hasValue
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Items Section (with pre-populated initial items) ─────────────────────────

class _ItemEntry {
  final nameCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    amountCtrl.dispose();
  }
}

class _EditItemsSection extends StatefulWidget {
  final List<Map<String, dynamic>> initialItems;
  const _EditItemsSection({super.key, required this.initialItems});

  @override
  State<_EditItemsSection> createState() => _EditItemsSectionState();
}

class _EditItemsSectionState extends State<_EditItemsSection> {
  late final List<_ItemEntry> _items;

  @override
  void initState() {
    super.initState();
    if (widget.initialItems.isEmpty) {
      _items = [_ItemEntry()];
    } else {
      _items = widget.initialItems.map((data) {
        final e = _ItemEntry();
        e.nameCtrl.text = data['name'] as String? ?? '';
        e.qtyCtrl.text = data['quantity'] as String? ?? '';
        final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
        if (amt > 0) e.amountCtrl.text = amt.toStringAsFixed(2);
        return e;
      }).toList();
    }
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  bool validate() {
    bool valid = true;
    for (final item in _items) {
      if (item.nameCtrl.text.trim().isEmpty) valid = false;
    }
    if (!valid) setState(() {});
    return valid;
  }

  List<Map<String, dynamic>> getItems() {
    return _items
        .map((item) => {
              'name': item.nameCtrl.text.trim(),
              'quantity': item.qtyCtrl.text.trim(),
              'amount':
                  double.tryParse(item.amountCtrl.text.trim()) ?? 0.0,
            })
        .toList();
  }

  void _addItem() => setState(() => _items.add(_ItemEntry()));

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
  );
  static final _focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide:
        const BorderSide(color: AppColors.primaryBlue, width: 1.5),
  );
  static final _errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.redAccent),
  );

  InputDecoration _dec(String hint, {bool isError = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall,
      filled: true,
      fillColor: AppColors.scaffoldBg,
      border: _border,
      enabledBorder: isError ? _errorBorder : _border,
      focusedBorder: _focusedBorder,
      errorBorder: _errorBorder,
      focusedErrorBorder: _errorBorder,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(_items.length, (i) {
          final item = _items[i];
          final isEmpty = item.nameCtrl.text.trim().isEmpty;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: item.nameCtrl,
                    style: AppTextStyles.tableCell,
                    onChanged: (_) => setState(() {}),
                    decoration:
                        _dec('Item name', isError: isEmpty),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 58,
                  child: TextField(
                    controller: item.qtyCtrl,
                    style: AppTextStyles.tableCell,
                    decoration: _dec('Qty'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 74,
                  child: TextField(
                    controller: item.amountCtrl,
                    style: AppTextStyles.tableCell,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: _dec('Amt'),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _items.length > 1
                      ? () => _removeItem(i)
                      : null,
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 20,
                    color: _items.length > 1
                        ? AppColors.redAccent
                        : AppColors.greyBorder,
                  ),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(
                      minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Add Item',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Status Selector ──────────────────────────────────────────────────────────

class _StatusSelector extends StatelessWidget {
  final MarketEntryStatus selected;
  final ValueChanged<MarketEntryStatus> onChanged;
  const _StatusSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flag_outlined,
                size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text('Entry Status', style: AppTextStyles.bodySmall),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: MarketEntryStatus.values.map((status) {
            final isSelected = status == selected;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: status != MarketEntryStatus.values.last
                      ? 8
                      : 0,
                ),
                child: GestureDetector(
                  onTap: () => onChanged(status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : AppColors.scaffoldBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      status.label,
                      style: AppTextStyles.badgeText.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Notes Field ──────────────────────────────────────────────────────────────

class _NotesField extends StatelessWidget {
  final TextEditingController controller;
  const _NotesField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    );
    return TextField(
      controller: controller,
      maxLines: 4,
      style: AppTextStyles.tableCell,
      decoration: InputDecoration(
        hintText: 'Add any notes about this trip…',
        hintStyle: AppTextStyles.bodySmall,
        prefixIcon: const Padding(
          padding:
              EdgeInsets.only(left: 12, right: 8, top: 14),
          child: Icon(Icons.notes_rounded,
              size: 20, color: AppColors.textSecondary),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: AppColors.scaffoldBg,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: AppColors.primaryBlue, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.fromLTRB(0, 14, 12, 14),
        alignLabelWithHint: true,
      ),
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool saving;
  const _SaveButton({required this.onTap, required this.saving});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: saving ? null : onTap,
        icon: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save_rounded, size: 20),
        label: Text(
          saving ? 'Saving…' : 'Update Entry',
          style: AppTextStyles.headingSmall
              .copyWith(color: Colors.white, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}
