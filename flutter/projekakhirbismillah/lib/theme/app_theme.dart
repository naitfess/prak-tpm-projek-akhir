import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light();
    return baseTheme.copyWith(
      primaryColor: AppColors.primaryGreen,
      primaryColorDark: AppColors.primaryGreenDark,
      scaffoldBackgroundColor: AppColors.backgroundLight,

      // ...existing theme code...
    );
  }
}
