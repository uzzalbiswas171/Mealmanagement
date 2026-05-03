import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  String? _groupId;
  String? _userId;
  String? _displayName;
  String? _role;
  int _defaultMorning = 0;
  int _defaultNoon = 1;
  int _defaultNight = 1;

  String? get groupId => _groupId;
  String? get userId => _userId;
  String? get displayName => _displayName;
  String? get role => _role;
  int get defaultMorning => _defaultMorning;
  int get defaultNoon => _defaultNoon;
  int get defaultNight => _defaultNight;

  bool get isManager => _role == 'manager';

  void setGroup({
    required String groupId,
    required String userId,
    required String displayName,
    required String role,
  }) {
    _groupId = groupId;
    _userId = userId;
    _displayName = displayName;
    _role = role;
    notifyListeners();
  }

  Future<void> loadFromFirestore(String groupId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final db = FirebaseFirestore.instance;

    final results = await Future.wait([
      db.collection('groups').doc(groupId).collection('members').doc(user.uid).get(),
      db.collection('groups').doc(groupId).get(),
    ]);

    final memberData = results[0].data();
    final groupData = results[1].data();

    _groupId = groupId;
    _userId = user.uid;
    _displayName = memberData?['displayName'] as String? ?? user.displayName ?? 'User';
    _role = memberData?['role'] as String? ?? 'member';
    _defaultMorning = (groupData?['defaultMorningMeal'] as num?)?.toInt() ?? 0;
    _defaultNoon = (groupData?['defaultNoonMeal'] as num?)?.toInt() ?? 1;
    _defaultNight = (groupData?['defaultNightMeal'] as num?)?.toInt() ?? 1;
    notifyListeners();
  }

  void clear() {
    _groupId = null;
    _userId = null;
    _displayName = null;
    _role = null;
    _defaultMorning = 0;
    _defaultNoon = 1;
    _defaultNight = 1;
    notifyListeners();
  }
}
