import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.navy,
      secondary: AppColors.teal,
      onSecondary: AppColors.beige,
      surface: AppColors.anthracite,
      onSurface: AppColors.beige,
      error: Color(0xFFE57373),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.navy,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.beige,
        displayColor: AppColors.beige,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.beige,
        titleTextStyle: TextStyle(
          color: AppColors.beige,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.anthracite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.anthracite,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.beigeMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      dividerTheme: DividerThemeData(color: AppColors.beigeFaint, space: 1),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.gold,
        textColor: AppColors.beige,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.gold),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.teal,
        contentTextStyle: TextStyle(color: AppColors.beige),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
