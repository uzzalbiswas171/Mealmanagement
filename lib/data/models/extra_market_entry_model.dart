import 'package:cloud_firestore/cloud_firestore.dart';

class ExtraMarketEntry {
  final String id;
  final String title;
  final double amount;
  final String addedBy;
  final String addedByName;
  final DateTime? date;
  final String? notes;
  final DateTime createdAt;

  const ExtraMarketEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.addedBy,
    required this.addedByName,
    this.date,
    this.notes,
    required this.createdAt,
  });

  factory ExtraMarketEntry.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final createdTs = d['createdAt'] as Timestamp?;
    final dateTs = d['date'] as Timestamp?;
    return ExtraMarketEntry(
      id: doc.id,
      title: d['title'] as String? ?? '',
      amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
      addedBy: d['addedBy'] as String? ?? '',
      addedByName: d['addedByName'] as String? ?? 'Unknown',
      date: dateTs?.toDate().toLocal(),
      notes: d['notes'] as String?,
      createdAt: createdTs?.toDate().toLocal() ?? DateTime.now(),
    );
  }
}
