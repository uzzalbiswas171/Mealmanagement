import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference _market(String groupId) =>
      _db.collection('groups').doc(groupId).collection('marketEntries');

  /// Live stream of market entries, newest first.
  static Stream<QuerySnapshot> watchMarketEntries(
    String groupId, {
    String? status,
  }) {
    Query q = _market(groupId).orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots();
  }

  /// Batch-writes a market entry + all its items atomically.
  static Future<String> addMarketEntry({
    required String groupId,
    required String title,
    required double totalAmount,
    required DateTime? tripDate,
    required String status,
    required String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final displayName =
        userDoc.data()?['fullName'] as String? ?? user.displayName ?? 'User';

    final tags = items
        .take(3)
        .map((i) => i['name'] as String)
        .where((n) => n.isNotEmpty)
        .toList();
    if (items.length > 3) tags.add('+${items.length - 3} more');

    final entryRef = _market(groupId).doc();
    final batch = _db.batch();

    batch.set(entryRef, {
      'title': title.trim(),
      'totalAmount': totalAmount,
      'tripDate': tripDate != null ? Timestamp.fromDate(tripDate) : null,
      'status': status,
      'notes': notes?.trim(),
      'createdBy': user.uid,
      'createdByName': displayName,
      'verificationCount': 0,
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (var i = 0; i < items.length; i++) {
      final itemRef = entryRef.collection('items').doc();
      batch.set(itemRef, {
        'name': items[i]['name'],
        'quantity': items[i]['quantity'],
        'amount': items[i]['amount'],
        'displayOrder': i,
      });
    }

    await batch.commit();
    return entryRef.id;
  }

  /// Live stream of items for a single market entry, ordered by displayOrder.
  static Stream<QuerySnapshot> watchMarketItems(
      String groupId, String entryId) {
    return _market(groupId)
        .doc(entryId)
        .collection('items')
        .orderBy('displayOrder')
        .snapshots();
  }

  /// One-time fetch of items for an entry, ordered by displayOrder.
  static Future<List<Map<String, dynamic>>> getMarketItems(
      String groupId, String entryId) async {
    final snap = await _market(groupId)
        .doc(entryId)
        .collection('items')
        .orderBy('displayOrder')
        .get();
    return snap.docs
        .map((d) => d.data())
        .toList();
  }

  /// Replaces all fields + items of an existing entry atomically.
  static Future<void> updateFullEntry({
    required String groupId,
    required String entryId,
    required String title,
    required double totalAmount,
    required DateTime? tripDate,
    required String status,
    required String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final tags = items
        .take(3)
        .map((i) => i['name'] as String)
        .where((n) => n.isNotEmpty)
        .toList();
    if (items.length > 3) tags.add('+${items.length - 3} more');

    // Fetch existing items to delete them first
    final existing = await _market(groupId)
        .doc(entryId)
        .collection('items')
        .get();

    final batch = _db.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final editorName =
        userDoc.data()?['fullName'] as String? ?? user.displayName ?? 'Unknown';

    final entryRef = _market(groupId).doc(entryId);
    batch.update(entryRef, {
      'title': title.trim(),
      'totalAmount': totalAmount,
      'tripDate': tripDate != null ? Timestamp.fromDate(tripDate) : null,
      'status': status,
      'notes': notes?.trim(),
      'tags': tags,
      'lastEditedBy': user.uid,
      'lastEditedByName': editorName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (var i = 0; i < items.length; i++) {
      final itemRef = entryRef.collection('items').doc();
      batch.set(itemRef, {
        'name': items[i]['name'],
        'quantity': items[i]['quantity'],
        'amount': items[i]['amount'],
        'displayOrder': i,
      });
    }

    await batch.commit();
  }

  /// Updates status or other fields of a market entry.
  static Future<void> updateMarketEntry({
    required String groupId,
    required String entryId,
    required Map<String, dynamic> changes,
  }) async {
    await _market(groupId).doc(entryId).update({
      ...changes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Current user verifies an entry. Prevents duplicate via doc ID = uid.
  static Future<void> verifyEntry({
    required String groupId,
    required String entryId,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final displayName =
        userDoc.data()?['fullName'] as String? ?? user.displayName ?? 'User';
    final avatarUrl = userDoc.data()?['avatarUrl'] as String?;

    final entryRef = _market(groupId).doc(entryId);
    final verifyRef =
        entryRef.collection('verifications').doc(user.uid);

    await _db.runTransaction((tx) async {
      final existing = await tx.get(verifyRef);
      if (existing.exists) return;
      tx.set(verifyRef, {
        'memberId': user.uid,
        'memberName': displayName,
        'avatarUrl': avatarUrl,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      tx.update(entryRef, {
        'verificationCount': FieldValue.increment(1),
      });
    });
  }
}
