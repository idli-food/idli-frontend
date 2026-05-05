import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Percentage of screen width (0–100)
  double wp(double pct) => screenWidth * pct / 100;

  /// Percentage of screen height (0–100)
  double hp(double pct) => screenHeight * pct / 100;

  /// Font size scaled to screen width (base design width: 390px)
  double sp(double size) =>
      (screenWidth / 390 * size).clamp(size * 0.85, size * 1.3);
}
