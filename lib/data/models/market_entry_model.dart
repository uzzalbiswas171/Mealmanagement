import 'package:cloud_firestore/cloud_firestore.dart';

enum MarketEntryStatus { completed, archived, pending }

extension MarketEntryStatusExtension on MarketEntryStatus {
  String get label {
    switch (this) {
      case MarketEntryStatus.completed:
        return 'Completed';
      case MarketEntryStatus.archived:
        return 'Archived';
      case MarketEntryStatus.pending:
        return 'Pending';
    }
  }
}

class MarketEntry {
  final String id;
  final String title;
  final double amount;
  final String dateLabel;
  final DateTime? rawDate;
  final MarketEntryStatus status;
  final List<String> tags;
  final List<String> verifierAvatarUrls;
  final String verifiedLabel;
  final String createdByName;
  final String? notes;
  final String? lastEditedByName;
  final DateTime? lastEditedAt;

  const MarketEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.dateLabel,
    this.rawDate,
    required this.status,
    required this.tags,
    required this.verifierAvatarUrls,
    required this.verifiedLabel,
    this.createdByName = '',
    this.notes,
    this.lastEditedByName,
    this.lastEditedAt,
  });

  factory MarketEntry.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final ts = d['tripDate'] as Timestamp? ?? d['createdAt'] as Timestamp?;
    return MarketEntry(
      id: doc.id,
      title: d['title'] as String? ?? '',
      amount: (d['totalAmount'] as num?)?.toDouble() ?? 0.0,
      dateLabel: _formatTs(ts),
      rawDate: ts?.toDate().toLocal(),
      status: MarketEntryStatus.values.firstWhere(
        (s) => s.name == (d['status'] as String?),
        orElse: () => MarketEntryStatus.pending,
      ),
      tags: List<String>.from(d['tags'] as List? ?? []),
      verifierAvatarUrls: [],
      verifiedLabel: _verifiedLabel((d['verificationCount'] as num?)?.toInt() ?? 0),
      createdByName: d['createdByName'] as String? ?? '',
      notes: d['notes'] as String?,
      lastEditedByName: d['lastEditedByName'] as String?,
      lastEditedAt: (d['updatedAt'] as Timestamp?)?.toDate().toLocal(),
    );
  }

  static String _formatTs(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate().toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dt.year, dt.month, dt.day);
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final t = '$h:$m $period';
    if (date == today) return 'Today, $t';
    if (date == yesterday) return 'Yesterday, $t';
    const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${mo[dt.month - 1]} ${dt.day}, $t';
  }

  static String _verifiedLabel(int count) {
    if (count == 0) return 'Not yet verified';
    if (count == 1) return 'Verified by 1 member';
    return 'Verified by $count members';
  }

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
}
