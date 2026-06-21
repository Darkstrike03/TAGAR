import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.leafGreen,
          primary: AppColors.leafGreen,
          onPrimary: AppColors.petalWhite,
          secondary: AppColors.earthBrown,
          onSecondary: AppColors.petalWhite,
          surface: AppColors.barkCream,
          onSurface: AppColors.forestGreen,
          error: AppColors.error,
          onError: AppColors.petalWhite,
          outline: AppColors.sandyBrown,
        ),
        scaffoldBackgroundColor: AppColors.petalWhite,
        fontFamily: GoogleFonts.notoSans().fontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.petalWhite,
          foregroundColor: AppColors.forestGreen,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: AppColors.forestGreen,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.barkCream,
          selectedItemColor: AppColors.leafGreen,
          unselectedItemColor: AppColors.earthBrown,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.leafGreen,
            foregroundColor: AppColors.petalWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.notoSans(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.petalWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.sandyBrown),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.sandyBrown),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.leafGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.barkCream,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.sandyBrown,
          thickness: 0.5,
        ),
      );
}
