import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemberService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference _members(String groupId) =>
      _db.collection('groups').doc(groupId).collection('members');

  /// Live stream of all active members in a group.
  static Stream<QuerySnapshot> watchMembers(String groupId) {
    return _members(groupId)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  /// Adds a member manually (manager action).
  static Future<void> addMember({
    required String groupId,
    required String displayName,
    required String phone,
    required String email,
    required String role,
    required double monthlyContribution,
    DateTime? joinedAt,
  }) async {
    final ref = _members(groupId).doc();
    await ref.set({
      'uid': ref.id,
      'displayName': displayName.trim(),
      'avatarUrl': null,
      'role': role,
      'joinedAt': joinedAt != null
          ? Timestamp.fromDate(joinedAt)
          : FieldValue.serverTimestamp(),
      'isActive': true,
      'monthlyContribution': monthlyContribution,
      'mealCount': 0,
      'moneyAmount': 0.0,
      'isPaid': false,
      'phone': phone.trim(),
      'email': email.trim(),
    });
  }

  /// Updates a member's fields.
  static Future<void> updateMember({
    required String groupId,
    required String memberId,
    required Map<String, dynamic> changes,
  }) async {
    await _members(groupId).doc(memberId).update({
      ...changes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Soft-removes a member (sets isActive = false).
  static Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    await _members(groupId).doc(memberId).update({'isActive': false});
  }

  /// Permanently deletes a member and all their associated data.
  static Future<void> deleteMember({
    required String groupId,
    required String memberId,
  }) async {
    final groupRef = _db.collection('groups').doc(groupId);

    // 1. Delete all meal entries for this member
    final meals = await groupRef
        .collection('mealEntries')
        .where('memberId', isEqualTo: memberId)
        .get();
    final batch = _db.batch();
    for (final doc in meals.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete market entries created by this member
    final markets = await groupRef
        .collection('marketEntries')
        .where('createdBy', isEqualTo: memberId)
        .get();
    for (final entry in markets.docs) {
      // Delete items subcollection
      final items = await entry.reference.collection('items').get();
      for (final item in items.docs) {
        batch.delete(item.reference);
      }
      // Delete verifications subcollection
      final verifs = await entry.reference.collection('verifications').get();
      for (final v in verifs.docs) {
        batch.delete(v.reference);
      }
      batch.delete(entry.reference);
    }

    // 3. Delete the member document itself
    batch.delete(_members(groupId).doc(memberId));

    await batch.commit();
  }

  static String get currentUid =>
      FirebaseAuth.instance.currentUser?.uid ?? '';
}
