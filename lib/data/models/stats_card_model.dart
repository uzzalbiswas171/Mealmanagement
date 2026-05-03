import 'package:flutter/material.dart';

class StatsCardData {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;

  const StatsCardData({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
  });
}
