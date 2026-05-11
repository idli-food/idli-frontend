import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6A30C1);
  static const Color primaryLight = Color(0xFF8B52D4);
  static const Color accent = Color(0xFFFDDA17);
  static const Color background = Color(0xFFFEFAF4);
  static const Color grey = Color(0xFFACACAC);
  static const Color greyDark = Color(0xFF838383);
  static const Color white = Color(0xFFFFFFFF);
  static const Color dark = Color(0xFF1A1A1A);
  static const Color tagBackground = Color(0xFFEEE6FF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppTextStyles {
  static const TextStyle primary = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle secondary = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.normal,
    color: AppColors.greyDark,
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter',
        useMaterial3: true,
      );
}
