import 'package:cloud_firestore/cloud_firestore.dart';
import 'member_model.dart';

class MealEntry {
  final Member member;
  final double morningMeal;
  final double noonMeal;
  final double nightMeal;
  final MealEditRecord? lastEdit;

  const MealEntry({
    required this.member,
    required this.morningMeal,
    required this.noonMeal,
    required this.nightMeal,
    this.lastEdit,
  });

  factory MealEntry.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final editTs = d['lastEditedAt'];
    return MealEntry(
      member: Member(
        id: d['memberId'] as String? ?? doc.id,
        name: d['memberName'] as String? ?? '',
      ),
      morningMeal: (d['morningMeal'] as num?)?.toDouble() ?? 0,
      noonMeal: (d['noonMeal'] as num?)?.toDouble() ?? 0,
      nightMeal: (d['nightMeal'] as num?)?.toDouble() ?? 0,
      lastEdit: editTs != null
          ? MealEditRecord(
              prevMorning:
                  (d['lastEditPrevMorning'] as num?)?.toDouble() ?? 0.0,
              prevNoon: (d['lastEditPrevNoon'] as num?)?.toDouble() ?? 0.0,
              prevNight: (d['lastEditPrevNight'] as num?)?.toDouble() ?? 0.0,
              editedAt: (editTs as Timestamp).toDate().toLocal(),
            )
          : null,
    );
  }

  double get totalMeals => morningMeal + noonMeal + nightMeal;
}

class MealEditRecord {
  final double prevMorning;
  final double prevNoon;
  final double prevNight;
  final DateTime editedAt;

  const MealEditRecord({
    required this.prevMorning,
    required this.prevNoon,
    required this.prevNight,
    required this.editedAt,
  });
}

class MealTableMeta {
  final String editorName;
  final String editorRole;
  final DateTime editedAt;
  final double mealRate;

  const MealTableMeta({
    required this.editorName,
    required this.editorRole,
    required this.editedAt,
    required this.mealRate,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(editedAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
