import 'package:cloud_firestore/cloud_firestore.dart';

class ExtraMarketService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference _col(String groupId) =>
      _db.collection('groups').doc(groupId).collection('extraMarket');

  /// Live stream of all extra market entries, newest first.
  static Stream<QuerySnapshot> watchEntries(String groupId) =>
      _col(groupId).orderBy('createdAt', descending: true).snapshots();

  static Future<void> addEntry({
    required String groupId,
    required String addedBy,
    required String addedByName,
    required String title,
    required double amount,
    DateTime? date,
    String? notes,
  }) =>
      _col(groupId).add({
        'title': title.trim(),
        'amount': amount,
        'addedBy': addedBy,
        'addedByName': addedByName.trim(),
        'date': date != null
            ? Timestamp.fromDate(date)
            : FieldValue.serverTimestamp(),
        'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  static Future<void> updateEntry({
    required String groupId,
    required String entryId,
    required String title,
    required double amount,
    DateTime? date,
    String? notes,
  }) =>
      _col(groupId).doc(entryId).update({
        'title': title.trim(),
        'amount': amount,
        if (date != null) 'date': Timestamp.fromDate(date),
        'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  static Future<void> deleteEntry({
    required String groupId,
    required String entryId,
  }) =>
      _col(groupId).doc(entryId).delete();
}
