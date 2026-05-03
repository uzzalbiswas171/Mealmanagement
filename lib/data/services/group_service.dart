import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  static final _db = FirebaseFirestore.instance;

  static String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Creates a new group and adds the current user as manager.
  /// Returns the new groupId.
  static Future<String> createGroup(String name) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc =
        await _db.collection('users').doc(user.uid).get();
    final displayName =
        userDoc.data()?['fullName'] as String? ?? user.displayName ?? 'User';
    final avatarUrl = userDoc.data()?['avatarUrl'] as String?;

    final inviteCode = _generateInviteCode();

    final groupRef = _db.collection('groups').doc();

    final batch = _db.batch();

    // Create group doc
    batch.set(groupRef, {
      'name': name.trim(),
      'inviteCode': inviteCode,
      'createdBy': user.uid,
      'currentMealRate': 60.0,
      'defaultMorningMeal': 0,
      'defaultNoonMeal': 1,
      'defaultNightMeal': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Add creator as manager member
    batch.set(groupRef.collection('members').doc(user.uid), {
      'uid': user.uid,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'role': 'manager',
      'joinedAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'monthlyContribution': 0.0,
      'mealCount': 0,
      'moneyAmount': 0.0,
      'isPaid': true,
      'phone': userDoc.data()?['phone'],
      'email': user.email,
    });

    // Store groupId on user doc
    batch.update(_db.collection('users').doc(user.uid), {
      'groupId': groupRef.id,
    });

    await batch.commit();
    return groupRef.id;
  }

  /// Joins an existing group via invite code. Returns the groupId.
  static Future<String> joinGroup(String inviteCode) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc =
        await _db.collection('users').doc(user.uid).get();
    final displayName =
        userDoc.data()?['fullName'] as String? ?? user.displayName ?? 'User';
    final avatarUrl = userDoc.data()?['avatarUrl'] as String?;

    final snap = await _db
        .collection('groups')
        .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception('Invalid invite code. Please check and try again.');
    }

    final groupRef = snap.docs.first.reference;

    final batch = _db.batch();

    batch.set(groupRef.collection('members').doc(user.uid), {
      'uid': user.uid,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'monthlyContribution': 0.0,
      'mealCount': 0,
      'moneyAmount': 0.0,
      'isPaid': false,
      'phone': userDoc.data()?['phone'],
      'email': user.email,
    });

    batch.update(_db.collection('users').doc(user.uid), {
      'groupId': groupRef.id,
    });

    await batch.commit();
    return groupRef.id;
  }

  static Future<DocumentSnapshot> getGroup(String groupId) {
    return _db.collection('groups').doc(groupId).get();
  }

  static Future<String?> getMemberRole(String groupId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(uid)
        .get();
    return doc.data()?['role'] as String?;
  }
}
