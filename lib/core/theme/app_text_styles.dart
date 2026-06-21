import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get logo => GoogleFonts.cormorantGaramond(
        fontWeight: FontWeight.w600,
        fontSize: 24,
        color: AppColors.forestGreen,
      );

  static TextStyle get h1 => GoogleFonts.dmSerifDisplay(
        fontSize: 24,
        color: AppColors.forestGreen,
      );

  static TextStyle get h2 => GoogleFonts.dmSerifDisplay(
        fontSize: 20,
        color: AppColors.forestGreen,
      );

  static TextStyle get body => GoogleFonts.notoSans(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: AppColors.forestGreen,
      );

  static TextStyle get bodyMedium => GoogleFonts.notoSans(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: AppColors.forestGreen,
      );

  static TextStyle get label => GoogleFonts.notoSans(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: AppColors.earthBrown,
      );

  static TextStyle get caption => GoogleFonts.notoSans(
        fontWeight: FontWeight.w400,
        fontSize: 12,
        color: AppColors.earthBrown,
      );

  static TextStyle get button => GoogleFonts.notoSans(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: AppColors.petalWhite,
      );
}
