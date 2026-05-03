import 'package:flutter/material.dart';

class ResponsiveHelper {
  ResponsiveHelper._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 600 && w < 900;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  static double heroBannerHeight(BuildContext context) =>
      isMobile(context) ? 180.0 : 240.0;

  static EdgeInsets screenPadding(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: isMobile(context) ? 16.0 : 24.0);

  static int statsColumnCount(BuildContext context) =>
      isMobile(context) ? 2 : 4;
}
