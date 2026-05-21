import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary:       AppColors.amber,
      secondary:     AppColors.cyan,
      surface:       AppColors.surface,
      error:         AppColors.red,
      onPrimary:     AppColors.bg,
      onSecondary:   AppColors.bg,
      onSurface:     AppColors.text,
      outline:       AppColors.line2,
    ),

    // ── Typo ──────────────────────────────────────────────
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 56, fontWeight: FontWeight.w600,
        color: AppColors.text, letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 40, fontWeight: FontWeight.w600,
        color: AppColors.text, letterSpacing: -1.0,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 32, fontWeight: FontWeight.w600,
        color: AppColors.text, letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24, fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: AppColors.text,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.textDim,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.textMute,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    ),

    // ── AppBar ────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg.withOpacity(0.85),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      iconTheme: const IconThemeData(color: AppColors.textDim),
    ),

    // ── BottomNavigationBar ───────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.amber,
      unselectedItemColor: AppColors.textMute,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),

    // ── Cards ─────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line2),
      ),
    ),

    // ── Input ─────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14, color: AppColors.textMute,
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14, color: AppColors.textDim,
      ),
    ),

    // ── ElevatedButton ────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.bg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── OutlinedButton ────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cyan2,
        side: const BorderSide(color: AppColors.cyan),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── TextButton ────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textDim,
        textStyle: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // ── Divider ───────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),

    // ── SnackBar ──────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface2,
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14, color: AppColors.text,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}