import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Member {
  final String id;
  final String name;

  const Member({required this.id, required this.name});

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }
}

enum MemberRole { manager, member, guest, bazarKari }

extension MemberRoleExtension on MemberRole {
  String get label {
    switch (this) {
      case MemberRole.manager:
        return 'Manager';
      case MemberRole.member:
        return 'Member';
      case MemberRole.guest:
        return 'Guest';
      case MemberRole.bazarKari:
        return 'Bazar Kari';
    }
  }

  Color get color {
    switch (this) {
      case MemberRole.manager:
        return const Color(0xFF2E7D32);
      case MemberRole.member:
        return const Color(0xFF757575);
      case MemberRole.guest:
        return const Color(0xFF6D4C41);
      case MemberRole.bazarKari:
        return const Color(0xFFE65100);
    }
  }
}

class MemberProfile {
  final String id;
  final String name;
  final String avatarUrl;
  final MemberRole role;
  final int mealCount;
  final double moneyAmount;
  final bool isPaid;
  final String phone;
  final String email;
  final double monthlyContribution;
  final DateTime? joinedAt;

  const MemberProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.role,
    required this.mealCount,
    required this.moneyAmount,
    required this.isPaid,
    this.phone = '',
    this.email = '',
    this.monthlyContribution = 0.0,
    this.joinedAt,
  });

  factory MemberProfile.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final ts = d['joinedAt'] as Timestamp?;
    return MemberProfile(
      id: doc.id,
      name: d['displayName'] as String? ?? '',
      avatarUrl: d['avatarUrl'] as String? ?? '',
      role: MemberRole.values.firstWhere(
        (r) => r.name == (d['role'] as String?),
        orElse: () => MemberRole.member,
      ),
      mealCount: (d['mealCount'] as num?)?.toInt() ?? 0,
      moneyAmount: (d['moneyAmount'] as num?)?.toDouble() ?? 0.0,
      isPaid: d['isPaid'] as bool? ?? false,
      phone: d['phone'] as String? ?? '',
      email: d['email'] as String? ?? '',
      monthlyContribution:
          (d['monthlyContribution'] as num?)?.toDouble() ?? 0.0,
      joinedAt: ts?.toDate(),
    );
  }

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  String get formattedMoney {
    final sign = moneyAmount >= 0 ? '+' : '';
    final amount = moneyAmount.abs().toInt();
    return '$sign\$$amount';
  }
}
