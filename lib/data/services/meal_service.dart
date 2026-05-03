import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MealService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference _meals(String groupId) =>
      _db.collection('groups').doc(groupId).collection('mealEntries');

  // Doc ID is deterministic so set() is always an upsert.
  static String _entryId(String memberId, DateTime date) {
    final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${memberId}_$d';
  }

  /// Live stream of all meal entries for a given date.
  static Stream<QuerySnapshot> watchMealsForDate(
      String groupId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _meals(groupId)
        .where('entryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('entryDate', isLessThan: Timestamp.fromDate(end))
        .snapshots();
  }

  /// Upsert meal counts for one member on one day.
  /// Also writes an editHistory record in the same transaction.
  static Future<void> upsertMeal({
    required String groupId,
    required String memberId,
    required String memberName,
    required DateTime date,
    required double morning,
    required double noon,
    required double night,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final entryRef = _meals(groupId).doc(_entryId(memberId, date));
    final historyRef = entryRef.collection('editHistory').doc();

    await _db.runTransaction((tx) async {
      final existing = await tx.get(entryRef);
      final prev = existing.exists ? existing.data() as Map<String, dynamic> : null;

      final entryData = <String, dynamic>{
        'memberId': memberId,
        'memberName': memberName,
        'entryDate': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'morningMeal': morning,
        'noonMeal': noon,
        'nightMeal': night,
        'totalMeals': morning + noon + night,
        'lastEditedBy': user.uid,
        'lastEditedByName': user.displayName ?? 'Unknown',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      // Store previous values on the doc so the table can show the edit strip
      // without needing an extra subcollection query.
      if (prev != null) {
        entryData['lastEditPrevMorning'] =
            (prev['morningMeal'] as num?)?.toDouble() ?? 0.0;
        entryData['lastEditPrevNoon'] =
            (prev['noonMeal'] as num?)?.toDouble() ?? 0.0;
        entryData['lastEditPrevNight'] =
            (prev['nightMeal'] as num?)?.toDouble() ?? 0.0;
        entryData['lastEditedAt'] = FieldValue.serverTimestamp();
      }
      tx.set(entryRef, entryData, SetOptions(merge: true));

      tx.set(historyRef, {
        'editedBy': user.uid,
        'editedByName': user.displayName ?? 'Unknown',
        'prevMorning': prev?['morningMeal'] ?? 0.0,
        'prevNoon': prev?['noonMeal'] ?? 0.0,
        'prevNight': prev?['nightMeal'] ?? 0.0,
        'newMorning': morning,
        'newNoon': noon,
        'newNight': night,
        'editedAt': FieldValue.serverTimestamp(),
      });
    });

    // Update denormalized mealCount on member doc (filter by memberId in Dart
    // to avoid needing a composite index on memberId + entryDate).
    final memberRef = _db
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(memberId);
    final monthStart = DateTime(date.year, date.month, 1);
    final monthEnd = DateTime(date.year, date.month + 1, 1);
    final monthMeals = await _meals(groupId)
        .where('entryDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('entryDate', isLessThan: Timestamp.fromDate(monthEnd))
        .get();

    final total = monthMeals.docs
        .where((d) =>
            (d.data() as Map<String, dynamic>)['memberId'] == memberId)
        .fold<double>(
          0,
          (acc, d) =>
              acc + ((d.data() as Map)['totalMeals'] as num).toDouble(),
        );
    await memberRef.update({'mealCount': total.toInt()});
  }

  /// Live stream of all meal entries for a given month.
  static Stream<QuerySnapshot> watchMealsForMonth(
      String groupId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return _meals(groupId)
        .where('entryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('entryDate', isLessThan: Timestamp.fromDate(end))
        .snapshots();
  }

  /// Live stream of meal entries within an inclusive date range.
  static Stream<QuerySnapshot> watchMealsForDateRange(
      String groupId, DateTime from, DateTime to) {
    return _meals(groupId)
        .where('entryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('entryDate', isLessThan: Timestamp.fromDate(to))
        .snapshots();
  }

  /// Returns the current meal rate for a group.
  static Future<double> getCurrentRate(String groupId) async {
    final doc = await _db.collection('groups').doc(groupId).get();
    return (doc.data()?['currentMealRate'] as num?)?.toDouble() ?? 60.0;
  }

  /// Sets a new meal rate (manager only).
  static Future<void> setRate({
    required String groupId,
    required double rate,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final batch = _db.batch();
    batch.update(_db.collection('groups').doc(groupId), {
      'currentMealRate': rate,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _db.collection('groups').doc(groupId).collection('mealRates').doc(),
      {
        'rate': rate,
        'effectiveFrom': Timestamp.fromDate(DateTime.now()),
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
  }
}
