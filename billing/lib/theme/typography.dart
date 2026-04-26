import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  // Headings (Outfit for a modern, tech feel)
  static TextStyle get h1 => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get h3 => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // Body (Inter for readability)
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  // Components
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      );

  static TextStyle get input => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      );

  static TextStyle get snackBar => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );
}
