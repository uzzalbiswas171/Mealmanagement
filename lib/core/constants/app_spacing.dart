import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const double cardRadius = 12.0;
  static const double badgeRadius = 20.0;
  static const double tableRadius = 12.0;

  static const BoxShadow cardShadow = BoxShadow(
    color: AppColors.shadowColor,
    blurRadius: 12,
    offset: Offset(0, 2),
    spreadRadius: 0,
  );

  static const BorderRadius cardBorderRadius =
      BorderRadius.all(Radius.circular(cardRadius));
}
